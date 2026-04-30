# Book Review App — End-to-End Deployment Guide

Complete step-by-step instructions to deploy the Book Review App on AWS (EKS + Aurora RDS)
using Terraform for infrastructure and Azure DevOps for CI/CD.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [AWS Account Setup](#2-aws-account-setup)
3. [Create Terraform State S3 Bucket](#3-create-terraform-state-s3-bucket)
4. [Set Up Azure DevOps Project](#4-set-up-azure-devops-project)
5. [Configure a Self-Hosted Agent](#5-configure-a-self-hosted-agent)
6. [Configure Pipeline Variables](#6-configure-pipeline-variables)
7. [Create the Pipeline](#7-create-the-pipeline)
8. [Run the Pipeline](#8-run-the-pipeline)
9. [Verify the Deployment](#9-verify-the-deployment)
10. [Access the Application](#10-access-the-application)
11. [Run Terraform Locally (optional)](#11-run-terraform-locally-optional)
12. [Tear Down Infrastructure](#12-tear-down-infrastructure)
13. [Troubleshooting](#13-troubleshooting)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Prerequisites

Install the following tools on your local machine **and** on the machine that will run
the Azure DevOps self-hosted agent.

### 1.1 Tools to install

| Tool | Version | Install guide |
|------|---------|---------------|
| AWS CLI | v2 | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| Terraform | >= 1.5 | https://developer.hashicorp.com/terraform/install |
| kubectl | >= 1.29 | https://kubernetes.io/docs/tasks/tools/ |
| Docker | Latest | https://docs.docker.com/get-docker/ |
| Git | Latest | https://git-scm.com/downloads |
| Node.js | 18.x | https://nodejs.org/en/download (optional — for local testing only) |

### 1.2 Verify installs

Run these commands to confirm everything is available:

```bash
aws --version
terraform --version
kubectl version --client
docker --version
git --version
```

---

## 2. AWS Account Setup

### 2.1 Create an IAM user for deployments

1. Log in to the **AWS Console** → search for **IAM** → click **Users** → **Create user**
2. Username: `book-review-deployer`
3. Select **Attach policies directly**
4. Attach these managed policies:
   - `AmazonEKSClusterPolicy`
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonVPCFullAccess`
   - `AmazonRDSFullAccess`
   - `IAMFullAccess`
   - `AmazonS3FullAccess`
5. Click **Create user**
6. Open the new user → **Security credentials** tab → **Create access key**
7. Choose **CLI** as the use case
8. **Save the Access Key ID and Secret Access Key** — you will not see the secret again

### 2.2 Configure AWS CLI locally

```bash
aws configure
```

Enter when prompted:
```
AWS Access Key ID:     <your access key id>
AWS Secret Access Key: <your secret access key>
Default region name:   us-east-1
Default output format: json
```

### 2.3 Verify AWS CLI works

```bash
aws sts get-caller-identity
```

You should see your account ID, user ID, and ARN printed.

---

## 3. Create Terraform State S3 Bucket

Terraform stores its state file in S3 so the pipeline can read it on every run.

Run these commands in your terminal (replace `123456789012` with your real AWS account ID):

```bash
# Create the bucket (bucket names must be globally unique — add your account ID)
aws s3api create-bucket \
  --bucket book-review-terraform-state-123456789012 \
  --region us-east-1

# Enable versioning so you can recover from accidental state corruption
aws s3api put-bucket-versioning \
  --bucket book-review-terraform-state-123456789012 \
  --versioning-configuration Status=Enabled

# Block all public access
aws s3api put-public-access-block \
  --bucket book-review-terraform-state-123456789012 \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Note down your bucket name — you will enter it as a pipeline variable in step 6.

---

## 4. Set Up Azure DevOps Project

### 4.1 Create a free Azure DevOps organization

1. Go to https://dev.azure.com
2. Sign in with a Microsoft account (create one free if needed)
3. Click **New organization** → follow the prompts
4. Organisation name: e.g., `my-devops-org`

### 4.2 Create a project

1. Inside your organization click **New project**
2. Project name: `book-review-capstone`
3. Visibility: **Private**
4. Click **Create**

### 4.3 Push the repository to Azure DevOps (or connect GitHub)

**Option A — use GitHub (recommended)**

1. In Azure DevOps, go to **Project Settings** → **Service connections**
2. Click **New service connection** → **GitHub** → **OAuth** → Authorize
3. Name it `github-connection`

**Option B — push directly to Azure Repos**

```bash
# Inside the book-review-app directory
git remote add azuredevops https://<org>@dev.azure.com/<org>/book-review-capstone/_git/book-review-app
git push azuredevops main
```

---

## 5. Configure a Self-Hosted Agent

The pipeline needs a machine with Docker, AWS CLI, Terraform, and kubectl.
A Linux VM (Ubuntu 22.04) works best. You can use an AWS EC2 t3.medium.

### 5.1 Launch the agent VM (EC2)

```bash
# Launch an Ubuntu 22.04 EC2 instance — t3.medium is sufficient
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.medium \
  --key-name <your-key-pair-name> \
  --security-group-ids <sg-with-ssh-open> \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=azdevops-agent}]'
```

SSH into the VM and run the setup below.

### 5.2 Install required tools on the agent VM

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify
aws --version && terraform --version && kubectl version --client && docker --version
```

### 5.3 Register the VM as an Azure DevOps agent

1. In Azure DevOps → **Project Settings** → **Agent pools** → **Add pool**
2. Pool name: `self-hosted-agent-pool` → **Create**
3. Click the new pool → **New agent** → select **Linux** → copy the download command
4. On the VM:

```bash
# Download and configure the agent (paste the exact URL from Azure DevOps)
mkdir myagent && cd myagent
curl -O https://vstsagentpackage.blob.core.windows.net/agent/3.x.x/vsts-agent-linux-x64-3.x.x.tar.gz
tar zxvf vsts-agent-linux-x64-3.x.x.tar.gz

# Run interactive config
./config.sh
```

When prompted:
- **Server URL**: `https://dev.azure.com/<your-org>`
- **Authentication type**: PAT
- **Personal access token**: create one at Azure DevOps → User Settings → Personal access tokens
  (scopes needed: Agent Pools — Read & Manage)
- **Agent pool**: `self-hosted-agent-pool`
- **Agent name**: leave default or type `agent-1`

```bash
# Install and start as a service
sudo ./svc.sh install
sudo ./svc.sh start
```

The agent status should show **Online** in Azure DevOps → Agent pools.

---

## 6. Configure Pipeline Variables

These variables are secret credentials — never commit them to git.

### 6.1 Create a Variable Group

1. In Azure DevOps → **Pipelines** → **Library** → **+ Variable group**
2. Name: `book-review-secrets`
3. Add each variable below (click the lock icon to mark it secret):

| Variable name | Value | Secret? |
|---------------|-------|---------|
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account ID | No |
| `AWS_ACCESS_KEY_ID` | IAM access key from step 2.1 | Yes |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key from step 2.1 | Yes |
| `TF_STATE_BUCKET` | S3 bucket name from step 3 | No |
| `DB_PASSWORD` | Strong password for Aurora (min 8 chars, letters+numbers) | Yes |
| `JWT_SECRET` | Random string for JWT signing (use: `openssl rand -hex 32`) | Yes |

4. Click **Save**

### 6.2 Generate a JWT secret (run locally)

```bash
openssl rand -hex 32
```

Copy the output and paste it as the `JWT_SECRET` value.

---

## 7. Create the Pipeline

### 7.1 Link the Variable Group to the pipeline

1. In Azure DevOps → **Pipelines** → **New pipeline**
2. Choose your source (GitHub or Azure Repos)
3. Select the `book-review-app` repository
4. Choose **Existing Azure Pipelines YAML file**
5. Branch: `main` — Path: `/azure-pipeline.yaml`
6. Click **Continue** — do NOT run yet

### 7.2 Attach the variable group

1. Click **Variables** → **Variable groups** → **Link variable group**
2. Select `book-review-secrets`
3. Click **Save**

---

## 8. Run the Pipeline

### 8.1 Trigger the first run

1. Click **Run pipeline** → **Run**
2. The pipeline has 3 stages that run in order:

```
Build  ──►  Infra  ──►  Deploy
```

| Stage | What happens | Approx time |
|-------|-------------|-------------|
| **Build** | Builds Docker images, pushes to ECR | 5–8 min |
| **Infra** | Terraform provisions VPC + EKS + Aurora RDS | 20–30 min |
| **Deploy** | kubectl applies manifests, rolls out pods | 3–5 min |

### 8.2 Monitor progress

- Click each stage to expand the job log in real time
- The **Infra** stage takes longest — EKS cluster creation alone takes ~15 minutes
- Watch for the final step in **Deploy** which prints the LoadBalancer URL

---

## 9. Verify the Deployment

After the pipeline succeeds, SSH into the agent VM (or run locally if kubectl is configured)
and run these checks.

### 9.1 Configure kubectl locally

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name book-review-production-eks
```

### 9.2 Check all pods are running

```bash
kubectl get pods -n book-review
```

Expected output (all pods should be `Running`):
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxxxxxxxx-xxxxx     1/1     Running   0          3m
backend-xxxxxxxxx-xxxxx     1/1     Running   0          3m
frontend-xxxxxxxxx-xxxxx    1/1     Running   0          3m
frontend-xxxxxxxxx-xxxxx    1/1     Running   0          3m
```

### 9.3 Check services

```bash
kubectl get svc -n book-review
```

Expected output:
```
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP                    PORT(S)
backend-service    ClusterIP      10.100.x.x      <none>                         3001/TCP
frontend-service   LoadBalancer   10.100.x.x      xxxx.elb.amazonaws.com         80:xxxxx/TCP
```

### 9.4 Get the LoadBalancer URL

```bash
kubectl get svc frontend-service -n book-review \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

It may take 2–3 minutes after the pipeline finishes for the NLB hostname to be assigned.

### 9.5 Test the backend API directly

```bash
# Replace BACKEND_POD with one of the backend pod names from step 9.2
kubectl exec -it <BACKEND_POD> -n book-review -- curl http://localhost:3001/
```

Expected: `Book Review API is running...`

### 9.6 Check backend logs

```bash
kubectl logs -l app=backend -n book-review --tail=50
```

You should see database sync and server startup messages without errors.

---

## 10. Access the Application

1. Copy the LoadBalancer hostname from step 9.4
2. Open a browser and navigate to:

```
http://<loadbalancer-hostname>
```

3. You should see the Book Review home page listing books
4. Register a user, log in, and post a review to confirm end-to-end functionality

> **Note:** DNS propagation for the NLB hostname can take up to 5 minutes.
> If the page does not load immediately, wait and refresh.

---

## 11. Run Terraform Locally (optional)

Use this if you want to provision infrastructure from your laptop instead of waiting
for the pipeline, or to inspect/debug the plan before committing.

### 11.1 Create your local tfvars file

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and fill in your real values — especially `db_password`.

### 11.2 Init, plan, apply

```bash
# Authenticate AWS CLI first (step 2.2)
cd terraform

terraform init \
  -backend-config="bucket=<your-tf-state-bucket>" \
  -backend-config="region=us-east-1"

terraform plan      # review what will be created
terraform apply     # type 'yes' when prompted
```

### 11.3 Retrieve outputs after apply

```bash
terraform output eks_cluster_name   # cluster name for kubectl
terraform output rds_endpoint       # Aurora writer endpoint for DB_HOST
```

---

## 12. Tear Down Infrastructure

When you are done, destroy all AWS resources to avoid charges.

### 12.1 Delete Kubernetes resources first

```bash
kubectl delete namespace book-review
```

This deletes all deployments, services, and pods in the namespace.

### 12.2 Destroy Terraform infrastructure

```bash
cd terraform

# Pass the DB password so Terraform can read the state
export TF_VAR_db_password="<your-db-password>"

terraform init \
  -backend-config="bucket=<your-tf-state-bucket>" \
  -backend-config="region=us-east-1"

terraform destroy -auto-approve
```

This will:
- Delete the EKS cluster and node group
- Delete the Aurora RDS cluster (creates a final snapshot first)
- Delete NAT Gateway, Elastic IP, subnets, VPC
- Takes approximately 15–20 minutes

### 12.3 Delete ECR images (optional)

```bash
aws ecr delete-repository --repository-name book-review-backend --force --region us-east-1
aws ecr delete-repository --repository-name book-review-frontend --force --region us-east-1
```

### 12.4 Delete the Terraform state bucket (optional)

```bash
aws s3 rm s3://<your-tf-state-bucket> --recursive
aws s3api delete-bucket --bucket <your-tf-state-bucket> --region us-east-1
```

---

## 13. Troubleshooting

### Pipeline fails at "Build" stage — Docker daemon not running

```bash
# On the agent VM
sudo systemctl start docker
sudo systemctl enable docker
```

### Pipeline fails at "Infra" stage — Terraform S3 backend error

- Verify the bucket name in `TF_STATE_BUCKET` exactly matches the bucket you created
- Verify the IAM user has `AmazonS3FullAccess`

### Pipeline fails at "Infra" stage — `Error: error creating EKS Cluster`

- Check IAM permissions include `IAMFullAccess`
- Verify the region supports EKS (us-east-1 does)

### Pods stuck in `Pending` state

```bash
kubectl describe pod <pod-name> -n book-review
```

Common causes:
- Not enough node capacity — check `eks_node_desired_size` in `terraform/variables.tf`
- Image pull failure — verify ECR image URL in the deployment manifest

### Pods in `CrashLoopBackOff`

```bash
kubectl logs <pod-name> -n book-review
```

Common causes:
- `DB_HOST` is wrong — check the ConfigMap has the correct RDS endpoint
- `DB_PASSWORD` mismatch — re-apply the secret: `kubectl delete secret app-secrets -n book-review` then re-run the pipeline

### LoadBalancer stuck in `<pending>` state

Wait 3–5 minutes. If it stays pending:
```bash
kubectl describe svc frontend-service -n book-review
```
Check for events mentioning IAM or subnet tagging issues.
The VPC subnets must have the tag `kubernetes.io/role/elb = 1` (already set by Terraform).

### Backend cannot connect to RDS

```bash
# Check the configmap has the right endpoint
kubectl get configmap backend-config -n book-review -o yaml
```

Verify the RDS security group allows inbound port 3306 from the EKS node security group.

---

## Final Checklist

- [x] Terraform provisions VPC, EKS cluster, and Aurora RDS automatically
- [x] EKS cluster with managed node group running in private subnets
- [x] Aurora MySQL RDS in private subnets, accessible only from EKS nodes
- [x] Azure DevOps pipeline with 3 stages: Build, Infra, Deploy
- [x] CI/CD triggers automatically on every push to `main`
- [x] Backend and frontend deployed to EKS with 2 replicas each
- [x] Application accessible via AWS Network Load Balancer on port 80
