# Book Review App — Hands-On Execution Guide
## Step-by-Step From Zero to Live on AWS

This guide walks through every single command and click needed to go from a
fresh machine to a fully running cloud-native application on AWS EKS + Aurora RDS,
automated end-to-end with Azure DevOps CI/CD.

---

## Architecture Overview

```
                          ┌─────────────────────────────────────────┐
                          │              AWS Cloud (us-east-1)       │
                          │                                          │
  User ──► NLB ──────────►│  EKS Cluster                            │
  (port 80)               │  ┌─────────────┐  ┌─────────────┐       │
                          │  │  Frontend   │  │   Backend   │       │
                          │  │  Pod × 2    │──►   Pod × 2   │──────►│── Aurora RDS
                          │  │  (Next.js)  │  │  (Express)  │       │   (MySQL 8.0)
                          │  └─────────────┘  └─────────────┘       │
                          │                                          │
                          │  Private Subnets ──────────────────────  │
                          │  Public  Subnets  (NAT, Load Balancer)   │
                          └─────────────────────────────────────────┘
                                        ▲
                                        │  kubectl apply
                                        │
                          ┌─────────────────────────┐
                          │   Azure DevOps Pipeline  │
                          │  Build → Infra → Deploy  │
                          └─────────────────────────┘
                                        ▲
                                        │  git push
                          ┌─────────────────────────┐
                          │   GitHub Repository      │
                          │   book-review-app        │
                          └─────────────────────────┘
```

---

## Table of Contents

- [Phase 1 — Install Tools on Your Machine](#phase-1--install-tools-on-your-machine)
- [Phase 2 — AWS Account and IAM Setup](#phase-2--aws-account-and-iam-setup)
- [Phase 3 — Create S3 Bucket for Terraform State](#phase-3--create-s3-bucket-for-terraform-state)
- [Phase 4 — Provision Infrastructure with Terraform](#phase-4--provision-infrastructure-with-terraform)
- [Phase 5 — Build and Push Docker Images to ECR](#phase-5--build-and-push-docker-images-to-ecr)
- [Phase 6 — Deploy Application to EKS](#phase-6--deploy-application-to-eks)
- [Phase 7 — Verify the Running Application](#phase-7--verify-the-running-application)
- [Phase 8 — Set Up Azure DevOps CI/CD Pipeline](#phase-8--set-up-azure-devops-cicd-pipeline)
- [Phase 9 — Test the Full CI/CD Flow](#phase-9--test-the-full-cicd-flow)
- [Phase 10 — Tear Down All Resources](#phase-10--tear-down-all-resources)

---

## Phase 1 — Install Tools on Your Machine

### Step 1.1 — Install AWS CLI v2

**Windows:**
```
Download: https://awscli.amazonaws.com/AWSCLIV2.msi
Run the installer → Next → Next → Install
```

**Linux / WSL:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
```

**Mac:**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o AWSCLIV2.pkg
sudo installer -pkg AWSCLIV2.pkg -target /
```

Verify:
```bash
aws --version
# Expected: aws-cli/2.x.x Python/3.x.x ...
```

---

### Step 1.2 — Install Terraform

**Windows:**
```
Download: https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_windows_amd64.zip
Unzip → move terraform.exe to C:\Windows\System32\
```

**Linux / WSL:**
```bash
sudo apt update && sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
```

**Mac:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Verify:
```bash
terraform --version
# Expected: Terraform v1.x.x
```

---

### Step 1.3 — Install kubectl

**Windows:**
```bash
# In PowerShell (run as Administrator)
curl.exe -LO "https://dl.k8s.io/release/v1.29.0/bin/windows/amd64/kubectl.exe"
# Move kubectl.exe to C:\Windows\System32\
```

**Linux / WSL:**
```bash
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Mac:**
```bash
brew install kubectl
```

Verify:
```bash
kubectl version --client
# Expected: Client Version: v1.29.x
```

---

### Step 1.4 — Install Docker

**Windows / Mac:**
```
Download Docker Desktop: https://www.docker.com/products/docker-desktop/
Run the installer → Start Docker Desktop
```

**Linux:**
```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker          # apply group change without logout
```

Verify:
```bash
docker --version
# Expected: Docker version 24.x.x
```

---

### Step 1.5 — Install Git (if not already installed)

**Windows:**
```
Download: https://git-scm.com/download/win
Run installer with all defaults
```

**Linux:**
```bash
sudo apt install -y git
```

**Mac:**
```bash
brew install git
```

Verify:
```bash
git --version
# Expected: git version 2.x.x
```

---

## Phase 2 — AWS Account and IAM Setup

### Step 2.1 — Create an AWS Account (skip if you already have one)

1. Go to https://aws.amazon.com
2. Click **Create an AWS Account**
3. Enter your email, account name, password
4. Choose **Personal** account type
5. Enter payment information (free tier available)
6. Complete phone verification
7. Select the **Free tier** support plan
8. Sign in to the AWS Console

---

### Step 2.2 — Create an IAM User for Deployments

**Why:** You should never use your root account for deployments. Create a dedicated IAM user.

1. In the AWS Console search bar type **IAM** → click **IAM**
2. In the left sidebar click **Users**
3. Click **Create user** (top right)
4. **User name:** `book-review-deployer`
5. Click **Next**
6. Select **Attach policies directly**
7. In the search box, add each of these policies one by one:
   - Search `AmazonEKSClusterPolicy` → check it
   - Search `AmazonEKSWorkerNodePolicy` → check it
   - Search `AmazonEC2ContainerRegistryFullAccess` → check it
   - Search `AmazonVPCFullAccess` → check it
   - Search `AmazonRDSFullAccess` → check it
   - Search `IAMFullAccess` → check it
   - Search `AmazonS3FullAccess` → check it
   - Search `AmazonEC2FullAccess` → check it
8. Click **Next** → **Create user**

---

### Step 2.3 — Create an Access Key for the IAM User

1. Click on the user `book-review-deployer`
2. Click the **Security credentials** tab
3. Scroll down to **Access keys** → click **Create access key**
4. Select **Command Line Interface (CLI)**
5. Tick the confirmation checkbox → click **Next** → **Create access key**
6. **IMPORTANT — copy both values now. You cannot see the secret again.**

```
Access key ID:     AKIA...............
Secret access key: ........................................
```

Save them in a password manager or text file on your machine.

---

### Step 2.4 — Configure AWS CLI with the IAM User

Open a terminal and run:

```bash
aws configure
```

Enter each value when prompted:
```
AWS Access Key ID [None]:     AKIA...............       ← paste your access key ID
AWS Secret Access Key [None]: ........................................  ← paste secret key
Default region name [None]:   us-east-1
Default output format [None]: json
```

**Test it works:**
```bash
aws sts get-caller-identity
```

Expected output (your account ID and ARN will differ):
```json
{
    "UserId": "AIDA...............",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/book-review-deployer"
}
```

Note down your **Account ID** (the 12-digit number). You will use it in later steps.

---

## Phase 3 — Create S3 Bucket for Terraform State

Terraform saves its state in S3 so the pipeline can read it on every run.

### Step 3.1 — Create the bucket

Replace `123456789012` with your real AWS account ID in every command below.

```bash
aws s3api create-bucket \
  --bucket book-review-tfstate-123456789012 \
  --region us-east-1
```

Expected output:
```json
{
    "Location": "/book-review-tfstate-123456789012"
}
```

### Step 3.2 — Enable versioning

```bash
aws s3api put-bucket-versioning \
  --bucket book-review-tfstate-123456789012 \
  --versioning-configuration Status=Enabled
```

### Step 3.3 — Block all public access

```bash
aws s3api put-public-access-block \
  --bucket book-review-tfstate-123456789012 \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Step 3.4 — Verify the bucket exists

```bash
aws s3 ls | grep book-review
```

Expected: `2024-xx-xx xx:xx:xx book-review-tfstate-123456789012`

---

## Phase 4 — Provision Infrastructure with Terraform

### Step 4.1 — Navigate to the terraform directory

```bash
cd book-review-app/terraform
```

### Step 4.2 — Create your terraform.tfvars file

```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` in any text editor and fill in the values:

```hcl
aws_region             = "us-east-1"
environment            = "production"
project_name           = "book-review"
vpc_cidr               = "10.0.0.0/16"

eks_cluster_version    = "1.29"
eks_node_instance_type = "t3.medium"
eks_node_desired_size  = 2
eks_node_min_size      = 1
eks_node_max_size      = 4

db_name                = "book_review_db"
db_username            = "admin"
db_password            = "BookReview2024!"    ← change to your own strong password
```

**Password rules:** minimum 8 characters, mix of uppercase, lowercase, and numbers.

---

### Step 4.3 — Update the S3 backend bucket name in providers.tf

Open `terraform/providers.tf` and change the bucket name to match yours:

```hcl
backend "s3" {
  bucket = "book-review-tfstate-123456789012"    ← your actual bucket name
  key    = "production/terraform.tfstate"
  region = "us-east-1"
}
```

---

### Step 4.4 — Initialize Terraform

```bash
terraform init
```

Expected output (last lines):
```
Terraform has been successfully initialized!
```

This downloads the AWS provider plugin (~30 MB) and connects to the S3 backend.

---

### Step 4.5 — Preview what Terraform will create

```bash
terraform plan
```

You will see a long list of resources to be created. Look for these key ones:

```
+ aws_vpc.this
+ aws_subnet.public[0], [1], [2]
+ aws_subnet.private[0], [1], [2]
+ aws_nat_gateway.this
+ aws_eks_cluster.this
+ aws_eks_node_group.this
+ aws_rds_cluster.this
+ aws_rds_cluster_instance.this[0], [1]
```

Total should be around **30–35 resources**. If you see any errors, fix them before continuing.

---

### Step 4.6 — Apply — create all AWS resources

```bash
terraform apply
```

Type `yes` when prompted:
```
Do you want to perform these actions? yes
```

**This takes 20–30 minutes.** The EKS cluster creation alone takes ~15 minutes.

You will see resources being created in order:
```
aws_vpc.this: Creating...
aws_vpc.this: Creation complete
aws_subnet.public[0]: Creating...
...
aws_eks_cluster.this: Creating...   ← wait here (10-15 min)
aws_eks_cluster.this: Creation complete
aws_eks_node_group.this: Creating...  ← wait here (5 min)
...
aws_rds_cluster.this: Creating...    ← wait here (5 min)
aws_rds_cluster.this: Creation complete
...
Apply complete! Resources: 34 added, 0 changed, 0 destroyed.
```

---

### Step 4.7 — Save the Terraform outputs

When apply finishes, run:

```bash
terraform output
```

Expected output:
```
eks_cluster_name    = "book-review-production-eks"
eks_cluster_endpoint = "https://XXXX.gr7.us-east-1.eks.amazonaws.com"
rds_endpoint        = "book-review-production-aurora-cluster.cluster-XXXX.us-east-1.rds.amazonaws.com"
rds_reader_endpoint = "book-review-production-aurora-cluster.cluster-ro-XXXX.us-east-1.rds.amazonaws.com"
vpc_id              = "vpc-XXXX"
```

**Copy the `rds_endpoint` value** — you need it in Phase 6 Step 6.2.

---

### Step 4.8 — Configure kubectl to connect to EKS

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name book-review-production-eks
```

Expected:
```
Added new context arn:aws:eks:us-east-1:123456789012:cluster/book-review-production-eks to ...
```

Test the connection:
```bash
kubectl get nodes
```

Expected (may take 1–2 minutes for nodes to be Ready):
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-10-xxx.ec2.internal   Ready    <none>   2m    v1.29.x
ip-10-0-11-xxx.ec2.internal   Ready    <none>   2m    v1.29.x
```

---

## Phase 5 — Build and Push Docker Images to ECR

### Step 5.1 — Create ECR repositories

```bash
# Backend repository
aws ecr create-repository \
  --repository-name book-review-backend \
  --region us-east-1

# Frontend repository
aws ecr create-repository \
  --repository-name book-review-frontend \
  --region us-east-1
```

Each command returns JSON with a `repositoryUri`. Note down both URIs. They follow
the pattern: `123456789012.dkr.ecr.us-east-1.amazonaws.com/book-review-backend`

---

### Step 5.2 — Authenticate Docker with ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

Replace `123456789012` with your account ID.

Expected: `Login Succeeded`

---

### Step 5.3 — Build and push the backend image

Go to the project root first:
```bash
cd book-review-app
```

Build:
```bash
docker build -t book-review-backend:latest ./backend
```

This takes 1–3 minutes on first build (downloads node:18-alpine base image).

Tag and push:
```bash
docker tag book-review-backend:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/book-review-backend:latest

docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/book-review-backend:latest
```

---

### Step 5.4 — Build and push the frontend image

Build:
```bash
docker build -t book-review-frontend:latest ./frontend
```

This takes 3–5 minutes (multi-stage build with `npm run build`).

Tag and push:
```bash
docker tag book-review-frontend:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/book-review-frontend:latest

docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/book-review-frontend:latest
```

---

### Step 5.5 — Verify images are in ECR

```bash
aws ecr list-images \
  --repository-name book-review-backend \
  --region us-east-1

aws ecr list-images \
  --repository-name book-review-frontend \
  --region us-east-1
```

Both should show an image with tag `latest`.

---

## Phase 6 — Deploy Application to EKS

### Step 6.1 — Create the Kubernetes namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

Expected: `namespace/book-review created`

Verify:
```bash
kubectl get namespaces | grep book-review
```

---

### Step 6.2 — Update the backend ConfigMap with the real RDS endpoint

Open `k8s/backend/configmap.yaml` in a text editor.

Find this line:
```yaml
  DB_HOST: "REPLACE_WITH_RDS_ENDPOINT"
```

Replace `REPLACE_WITH_RDS_ENDPOINT` with the `rds_endpoint` value from Step 4.7.

Example after editing:
```yaml
  DB_HOST: "book-review-production-aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com"
```

Save the file.

---

### Step 6.3 — Update the deployment files with your ECR account ID

In `k8s/backend/deployment.yaml` find:
```yaml
image: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/book-review-backend:IMAGE_TAG
```

Replace `ACCOUNT_ID` with your 12-digit AWS account ID and `IMAGE_TAG` with `latest`:
```yaml
image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/book-review-backend:latest
```

In `k8s/frontend/deployment.yaml` do the same:
```yaml
image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/book-review-frontend:latest
```

Save both files.

---

### Step 6.4 — Create the Kubernetes secret for DB password and JWT

Generate a JWT secret:
```bash
# On Linux/Mac:
openssl rand -hex 32

# On Windows PowerShell:
[System.Web.Security.Membership]::GeneratePassword(32, 8)
```

Copy the output. Now create the secret in Kubernetes:

```bash
kubectl create secret generic app-secrets \
  --namespace=book-review \
  --from-literal=DB_PASSWORD='BookReview2024!' \
  --from-literal=JWT_SECRET='your-generated-jwt-secret-here'
```

Replace `BookReview2024!` with the same password you used in `terraform.tfvars`.

Expected: `secret/app-secrets created`

---

### Step 6.5 — Apply the backend ConfigMap

```bash
kubectl apply -f k8s/backend/configmap.yaml
```

Expected: `configmap/backend-config created`

---

### Step 6.6 — Deploy the backend

```bash
kubectl apply -f k8s/backend/deployment.yaml
kubectl apply -f k8s/backend/service.yaml
```

Expected:
```
deployment.apps/backend created
service/backend-service created
```

---

### Step 6.7 — Deploy the frontend

```bash
kubectl apply -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml
```

Expected:
```
deployment.apps/frontend created
service/frontend-service created
```

---

### Step 6.8 — Wait for pods to start

```bash
kubectl rollout status deployment/backend  -n book-review --timeout=180s
kubectl rollout status deployment/frontend -n book-review --timeout=180s
```

Expected (after 1–3 minutes):
```
deployment "backend" successfully rolled out
deployment "frontend" successfully rolled out
```

---

## Phase 7 — Verify the Running Application

### Step 7.1 — Check all pods are Running

```bash
kubectl get pods -n book-review
```

Expected output — all pods `Running`, `READY 1/1`:
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-7d9f8b6c4-abc12     1/1     Running   0          2m
backend-7d9f8b6c4-def34     1/1     Running   0          2m
frontend-6c8d7f9b5-ghi56    1/1     Running   0          2m
frontend-6c8d7f9b5-jkl78    1/1     Running   0          2m
```

If any pod shows `CrashLoopBackOff` or `Error`, check logs:
```bash
kubectl logs <pod-name> -n book-review
```

---

### Step 7.2 — Check services and get the LoadBalancer address

```bash
kubectl get svc -n book-review
```

Expected:
```
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP                    PORT(S)
backend-service    ClusterIP      10.100.x.x      <none>                         3001/TCP
frontend-service   LoadBalancer   10.100.x.x      xxxx.elb.amazonaws.com         80:31xxx/TCP
```

The `EXTERNAL-IP` for `frontend-service` is your public URL.
It takes 2–3 minutes after service creation to be assigned.

Get just the hostname:
```bash
kubectl get svc frontend-service -n book-review \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

### Step 7.3 — Test the backend API is reachable from inside the cluster

```bash
# Get any backend pod name
BACKEND_POD=$(kubectl get pods -n book-review -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Curl the backend health endpoint from inside the pod
kubectl exec -it $BACKEND_POD -n book-review -- wget -qO- http://localhost:3001/
```

Expected: `Book Review API is running...`

---

### Step 7.4 — Test the backend can reach the database

```bash
kubectl logs $BACKEND_POD -n book-review | grep -E "Database|✅|❌"
```

Expected lines:
```
✅ Database schema updated successfully!
👤 Sample users added!
📚 Sample books added!
✍️ Sample reviews added!
```

If you see `❌` or connection errors, the DB_HOST in the configmap is wrong.
Re-check the RDS endpoint and update: `kubectl apply -f k8s/backend/configmap.yaml`
then restart pods: `kubectl rollout restart deployment/backend -n book-review`

---

### Step 7.5 — Open the application in a browser

Copy the LoadBalancer hostname from Step 7.2 and open:

```
http://<loadbalancer-hostname>
```

You should see the **Book Review home page** with a list of books.

**Test the full flow:**
1. Click **Register** — create an account with email and password
2. Click **Login** — sign in with those credentials
3. Click on a book — you should see its details page
4. Write a review and submit it — the review should appear immediately
5. Log out and log back in — your review should still be there

---

## Phase 8 — Set Up Azure DevOps CI/CD Pipeline

This phase automates everything you did manually in Phases 4–6.
Every `git push` to `main` will trigger a full build → infra → deploy pipeline.

### Step 8.1 — Create an Azure DevOps Organization

1. Open https://dev.azure.com in your browser
2. Sign in with a Microsoft account (create one free at https://account.microsoft.com if needed)
3. Click **Create new organization**
4. Organization name: `<yourname>-devops` (must be globally unique)
5. Region: choose closest to you → **Continue**

---

### Step 8.2 — Create a Project

1. Inside your new organization click **+ New project**
2. Project name: `book-review-capstone`
3. Visibility: **Private**
4. Click **Create**

---

### Step 8.3 — Connect your GitHub repository

1. In your project go to **Project Settings** (bottom-left gear icon)
2. Click **Service connections** → **New service connection**
3. Select **GitHub** → click **Next**
4. Click **Authorize** → log in to GitHub → **Authorize AzurePipelines**
5. Connection name: `github-connection`
6. Click **Save**

---

### Step 8.4 — Create a Personal Access Token (PAT) for the agent

1. Click your avatar (top right in Azure DevOps) → **Personal access tokens**
2. Click **+ New Token**
3. Name: `agent-pat`
4. Expiration: 90 days
5. Scopes: select **Agent Pools** → check **Read & manage**
6. Click **Create**
7. **Copy the token now** — it is shown only once

---

### Step 8.5 — Launch an EC2 instance to run the Azure DevOps agent

```bash
# Get the latest Ubuntu 22.04 AMI ID
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text \
  --region us-east-1)

echo "Using AMI: $AMI_ID"

# Create a security group allowing SSH
aws ec2 create-security-group \
  --group-name agent-sg \
  --description "Azure DevOps agent security group" \
  --region us-east-1

AGENT_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=agent-sg" \
  --query "SecurityGroups[0].GroupId" --output text)

# Allow SSH from anywhere (restrict to your IP for better security)
aws ec2 authorize-security-group-ingress \
  --group-id $AGENT_SG \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create a key pair (skip if you already have one)
aws ec2 create-key-pair \
  --key-name book-review-key \
  --query 'KeyMaterial' \
  --output text > book-review-key.pem

chmod 400 book-review-key.pem

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.medium \
  --key-name book-review-key \
  --security-group-ids $AGENT_SG \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=azdevops-agent}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance to start
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get the public IP
AGENT_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Agent IP: $AGENT_IP"
```

---

### Step 8.6 — Install tools on the agent VM

SSH into the VM:
```bash
ssh -i book-review-key.pem ubuntu@$AGENT_IP
```

Run all of the following on the VM:

```bash
# ── System update ────────────────────────────────────────────────────────────
sudo apt update && sudo apt upgrade -y

# ── Docker ───────────────────────────────────────────────────────────────────
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
newgrp docker

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
aws --version

# ── Terraform ─────────────────────────────────────────────────────────────────
sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
terraform --version

# ── kubectl ───────────────────────────────────────────────────────────────────
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# ── AWS credentials on the agent ─────────────────────────────────────────────
aws configure
# Enter: your Access Key ID, Secret Key, region us-east-1, format json
```

---

### Step 8.7 — Register the VM as an Azure DevOps agent

Still inside the VM:

```bash
# Create agent directory
mkdir ~/myagent && cd ~/myagent

# Download the agent (get the exact URL from Azure DevOps UI)
# Azure DevOps → Project Settings → Agent pools → Add pool → New agent → Linux
# Copy the download URL shown there. It looks like:
curl -O https://vstsagentpackage.blob.core.windows.net/agent/3.236.1/vsts-agent-linux-x64-3.236.1.tar.gz

# Extract
tar zxvf vsts-agent-linux-x64-*.tar.gz

# Configure the agent (interactive)
./config.sh
```

When prompted enter:
```
Server URL:                    https://dev.azure.com/<your-org-name>
Authentication type:           PAT
Personal access token:         <paste the PAT from Step 8.4>
Agent pool (press enter = default): self-hosted-agent-pool
Agent name (press enter = hostname): agent-1
Work folder (press enter = _work):  (press Enter)
```

Install and start as a service:
```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

Expected: `active (running)`

Back in Azure DevOps → **Project Settings** → **Agent pools** → `self-hosted-agent-pool`
→ **Agents** tab → your agent should show **Online** (green dot).

Exit the SSH session:
```bash
exit
```

---

### Step 8.8 — Create the Variable Group in Azure DevOps

1. In Azure DevOps go to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name: `book-review-secrets`
4. Add each variable below. Click the **lock icon** to mark it secret:

| Variable | Value | Secret? |
|----------|-------|---------|
| `AWS_ACCOUNT_ID` | your 12-digit account ID | No |
| `AWS_ACCESS_KEY_ID` | your IAM access key | Yes (lock it) |
| `AWS_SECRET_ACCESS_KEY` | your IAM secret key | Yes (lock it) |
| `TF_STATE_BUCKET` | `book-review-tfstate-123456789012` | No |
| `DB_PASSWORD` | `BookReview2024!` (same as terraform.tfvars) | Yes (lock it) |
| `JWT_SECRET` | output of `openssl rand -hex 32` | Yes (lock it) |

5. Click **Save**

---

### Step 8.9 — Create the pipeline in Azure DevOps

1. Go to **Pipelines** → **New pipeline**
2. Select **GitHub**
3. Choose your `book-review-app` repository
4. Select **Existing Azure Pipelines YAML file**
5. Branch: `main` | Path: `/azure-pipeline.yaml`
6. Click **Continue**
7. On the review screen click **Variables** → **Variable groups** → **Link variable group**
8. Select `book-review-secrets` → **Link**
9. Click **Save** (NOT "Save and run" yet)

---

## Phase 9 — Test the Full CI/CD Flow

### Step 9.1 — Make a small change to trigger the pipeline

On your local machine:

```bash
cd book-review-app

# Make a trivial change to trigger the pipeline
echo "# CI/CD Test $(date)" >> README.md

git add README.md
git commit -m "test: trigger Azure DevOps pipeline"
git push origin main
```

---

### Step 9.2 — Watch the pipeline run in Azure DevOps

1. Go to **Pipelines** → **Pipelines** → click the running pipeline
2. You will see 3 stages:

```
Stage 1: Build          (5–8 min)   — builds Docker images, pushes to ECR
Stage 2: Infra          (20–30 min) — terraform apply (only changes on re-run)
Stage 3: Deploy         (3–5 min)   — kubectl apply, rollout
```

3. Click any stage to see its live logs
4. When all 3 stages show a green tick, the deployment is complete

---

### Step 9.3 — Read the LoadBalancer URL from the pipeline output

1. Click the **Deploy** stage → click **Apply Kubernetes manifests** job
2. Scroll to the last step: **Print deployment status and LoadBalancer URL**
3. The final line shows the NLB hostname:
   ```
   LoadBalancer URL:
   abc123.elb.amazonaws.com
   ```

---

### Step 9.4 — Confirm CI/CD works end-to-end

Make a visible change in the app — for example, open `frontend/src/app/page.js`
and change the page title, then push:

```bash
git add .
git commit -m "feat: update home page title"
git push origin main
```

Watch the pipeline re-run automatically. After ~10 minutes, reload the browser —
the change should be live.

---

## Phase 10 — Tear Down All Resources

Run this when you are done to avoid AWS charges.

### Step 10.1 — Delete Kubernetes resources

```bash
kubectl delete namespace book-review
```

Wait for confirmation: `namespace "book-review" deleted`

---

### Step 10.2 — Destroy Terraform infrastructure

```bash
cd book-review-app/terraform

export TF_VAR_db_password="BookReview2024!"

terraform destroy
```

Type `yes` when prompted. This takes 15–20 minutes.

Watch for these resources being destroyed:
```
aws_eks_node_group.this: Destroying...        (5 min)
aws_eks_cluster.this: Destroying...           (10 min)
aws_rds_cluster_instance.this[0]: Destroying... (3 min)
aws_rds_cluster.this: Destroying...           (2 min)
aws_nat_gateway.this: Destroying...
aws_vpc.this: Destroying...
...
Destroy complete! Resources: 34 destroyed.
```

---

### Step 10.3 — Delete ECR images

```bash
aws ecr delete-repository \
  --repository-name book-review-backend \
  --force --region us-east-1

aws ecr delete-repository \
  --repository-name book-review-frontend \
  --force --region us-east-1
```

---

### Step 10.4 — Terminate the Azure DevOps agent EC2 instance

```bash
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
```

---

### Step 10.5 — Delete the Terraform state S3 bucket

```bash
# Empty the bucket first (required before deletion)
aws s3 rm s3://book-review-tfstate-123456789012 --recursive

# Delete the bucket
aws s3api delete-bucket \
  --bucket book-review-tfstate-123456789012 \
  --region us-east-1
```

---

### Step 10.6 — Verify no resources remain (avoid surprise charges)

```bash
# Check no EKS clusters remain
aws eks list-clusters --region us-east-1

# Check no RDS clusters remain
aws rds describe-db-clusters --region us-east-1 \
  --query "DBClusters[*].DBClusterIdentifier"

# Check no EC2 instances running (besides anything you already had)
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value[]"
```

All lists should be empty (or only show resources you intentionally kept).

---

## Final Checklist

```
[✓] Terraform provisions VPC, EKS, and Aurora RDS automatically
[✓] EKS cluster with 2 managed worker nodes across 3 availability zones
[✓] Aurora MySQL 8.0 with 2 instances (writer + reader) in private subnets
[✓] ECR repositories for backend and frontend Docker images
[✓] Kubernetes namespace, deployments, services, configmap, and secrets applied
[✓] Backend (Express + Sequelize) running with 2 replicas inside EKS
[✓] Frontend (Next.js) running with 2 replicas inside EKS
[✓] Application publicly accessible via AWS Network Load Balancer on port 80
[✓] Azure DevOps pipeline with 3 stages: Build → Infra → Deploy
[✓] CI/CD triggers automatically on every git push to main
[✓] No manual steps — everything is code and pipeline
```
