# EpicBook — End-to-End DevOps Deployment Guide

A two-pipeline DevOps project that provisions Azure infrastructure with Terraform and deploys the EpicBook Node.js application with Ansible, orchestrated through Azure DevOps.

---

## Architecture Overview

```
Developer pushes code
         |
         v
 ┌───────────────────────────────────────────┐
 │           STAGE 1 — Infra Pipeline        │
 │           (infra-epicbook repo)            │
 │                                           │
 │  Terraform:                               │
 │   Resource Group (epic-book-rg)           │
 │   VNet + Subnets (web + db)               │
 │   NSG (allow 22, 80)                      │
 │   Public IP (zone 2)                      │
 │   Ubuntu VM — Standard_D2s_v3 (zone 2)   │
 │   MySQL Flexible Server (private VNet)    │
 │   Private DNS zone                        │
 │                                           │
 │  Publishes artifact: infra-outputs.env    │
 │   vmPublicIp=x.x.x.x                     │
 │   db_host=xxx.mysql.database.azure.com    │
 └──────────────────┬────────────────────────┘
                    │  triggers automatically
                    v
 ┌───────────────────────────────────────────┐
 │           STAGE 2 — App Pipeline          │
 │           (theepicbook repo)              │
 │                                           │
 │  Ansible roles on the VM:                │
 │   common  → Node.js 20, base packages    │
 │   nginx   → reverse proxy :80 → :3000    │
 │   epicbook→ clone app, seed DB, pm2      │
 │                                           │
 │  Verifies: curl http://<vmPublicIp>       │
 └───────────────────────────────────────────┘
                    |
                    v
          EpicBook running at
          http://<vmPublicIp>
```

---

## Repository Structure

```
bookreview_project/
├── infra-epicbook/              # Terraform — Azure infrastructure
│   ├── main.tf                  # All Azure resources
│   ├── variables.tf             # Input variable definitions
│   ├── outputs.tf               # Exports: public_ip, db_host, admin_user
│   ├── backend.tf               # Remote state in Azure Blob Storage
│   ├── terraform.tfvars         # Non-secret values (region, sizing, names)
│   ├── infra-pipelines.yml      # Azure DevOps pipeline (Stage 1)
│   └── .gitignore
│
└── app-deploy-epicbook/         # Ansible — application deployment
    ├── site.yml                 # Master playbook (common → nginx → epicbook)
    ├── azure-pipelines.yml      # Azure DevOps pipeline (Stage 2)
    ├── inventory.ini            # Placeholder — overwritten at runtime
    ├── ansible.cfg              # Ansible defaults
    ├── group_vars/web/main.yml  # Non-secret app variables
    ├── roles/
    │   ├── common/              # Node.js 20, base OS hardening
    │   ├── nginx/               # Nginx install + reverse proxy config
    │   └── epicbook/            # App clone, DB seed, pm2 process manager
    └── .gitignore
```

---

## Infrastructure Details

| Resource | Value |
|---|---|
| Region | Central India |
| Resource Group | `epic-book-rg` |
| VM Size | `Standard_D2s_v3` |
| VM Zone | `2` |
| OS Image | Ubuntu 22.04 LTS (`22_04-lts`) |
| VM Admin User | `azureuser` |
| Auth Method | SSH key only (password disabled) |
| MySQL Version | 8.0.21 |
| MySQL SKU | `B_Standard_B1ms` |
| MySQL Access | Private VNet only |
| DB Name | `bookstore` |
| DB User | `epicbook_user` |
| Terraform State | Azure Blob (`epicbooktfstate01/tfstate`) |

---

## Prerequisites

Before executing anything, confirm you have:

- [ ] An active **Azure subscription**
- [ ] An **Azure DevOps organization and project** (e.g., project name: `EpicBook`)
- [ ] Azure CLI installed locally (`az --version`)
- [ ] Git installed locally
- [ ] A Linux machine (or WSL / Ubuntu VM) to run the self-hosted agent

---

## Phase 0 — Collect Azure Credentials (Do This First)

You need four values from Azure AD. These are used to create the service connection.

### Create the App Registration (Service Principal)

1. Azure Portal → **Azure Active Directory** → **App registrations** → **New registration**
2. Name: `epicbook-spn` → click **Register**
3. On the overview page, copy:
   - **Application (client) ID** → save as `CLIENT_ID`
   - **Directory (tenant) ID** → save as `TENANT_ID`
4. Go to **Certificates & secrets** → **New client secret**
   - Description: `epicbook-pipeline`
   - Expiry: 12 months
   - Click **Add** → copy the **Value immediately** (shown only once) → save as `CLIENT_SECRET`

### Grant the SPN Access to Your Subscription

5. Azure Portal → **Subscriptions** → select your subscription → copy **Subscription ID** → save as `SUBSCRIPTION_ID`
6. In your subscription → **Access control (IAM)** → **Add role assignment**
   - Role: **Contributor**
   - Members: search for `epicbook-spn` → select → **Review + assign**

You now have all four values needed:

```
TENANT_ID        = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SUBSCRIPTION_ID  = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
CLIENT_ID        = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
CLIENT_SECRET    = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Phase 1 — Create the Terraform State Backend

Terraform stores its state remotely in Azure Blob Storage. This resource group and storage account must exist **before** the pipeline runs.

Run the following in **Azure Cloud Shell** or your local terminal with Azure CLI logged in:

```bash
# Login if running locally
az login

# Create resource group for state storage
az group create \
  --name rg-tfstate \
  --location "Central India"

# Create storage account (globally unique name required)
az storage account create \
  --name epicbooktfstate01 \
  --resource-group rg-tfstate \
  --location "Central India" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2

# Create the blob container
az storage container create \
  --name tfstate \
  --account-name epicbooktfstate01
```

> These names are hardcoded in `infra-epicbook/backend.tf`. If you change the storage account name, update `backend.tf` to match before pushing.

---

## Phase 2 — Generate SSH Key Pair

The VM is created with SSH key authentication only. You generate this once locally.

```bash
# Run in Git Bash, WSL, or Linux terminal
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Verify both files exist
ls -l ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
```

- `~/.ssh/id_rsa.pub` → uploaded as Secure File → Terraform places it on the VM during provisioning
- `~/.ssh/id_rsa` → uploaded as Secure File → Ansible uses it to SSH into the VM

Keep both files. Do not commit them to Git.

---

## Phase 3 — Push Repositories to Azure DevOps

In your Azure DevOps project, create two Git repositories with these exact names:

| Repo name | Source directory |
|---|---|
| `infra-epicbook` | `infra-epicbook/` |
| `theepicbook` | `app-deploy-epicbook/` |

> The name `theepicbook` must match exactly — the app pipeline's `resources.pipelines.source` field references `infra-epicbook.git` and the pipeline source name is derived from the repo name.

```bash
# Push infra repo
cd /path/to/infra-epicbook
git remote add origin https://dev.azure.com/<YOUR_ORG>/EpicBook/_git/infra-epicbook
git push -u origin main

# Push app repo
cd /path/to/app-deploy-epicbook
git remote add origin https://dev.azure.com/<YOUR_ORG>/EpicBook/_git/theepicbook
git push -u origin main
```

Replace `<YOUR_ORG>` with your Azure DevOps organization name.

---

## Phase 4 — Configure Azure DevOps (One-Time Setup)

All four steps below are done inside your `EpicBook` Azure DevOps project.

### 4A — Create Service Connection

This allows Terraform in the pipeline to authenticate to Azure using the SPN.

1. **Project Settings** → **Service connections** → **New service connection**
2. Select **Azure Resource Manager** → **Next**
3. Select **Service principal (manual)** → **Next**
4. Fill in the form:

   | Field | Value |
   |---|---|
   | Environment | Azure Cloud |
   | Scope level | Subscription |
   | Subscription Id | `SUBSCRIPTION_ID` |
   | Subscription Name | your subscription name |
   | Service Principal Id | `CLIENT_ID` |
   | Credential | Service principal key |
   | Service principal key | `CLIENT_SECRET` |
   | Tenant ID | `TENANT_ID` |

5. Click **Verify** — it must show a green tick
6. **Service connection name**: `azure-devops-connection` ← must be exactly this
7. Check **Grant access permission to all pipelines** → **Save**

### 4B — Create Variable Group

This holds the database password as a secret — never stored in code.

1. **Pipelines** → **Library** → **+ Variable group**
2. **Variable group name**: `epicbook-secrets` ← must be exactly this
3. Click **+ Add variable**:

   | Name | Value | Secret |
   |---|---|---|
   | `db_password` | `YourStrongPassword@2025` | Yes (click the lock icon) |

4. **Save**

### 4C — Upload SSH Keys as Secure Files

1. **Pipelines** → **Library** → **Secure files** tab → **+ Secure file**
2. Upload `~/.ssh/id_rsa.pub` → filename must be saved as `id_rsa.pub`
3. Upload `~/.ssh/id_rsa` → filename must be saved as `id_rsa`
4. Click each uploaded file → toggle **Authorize for use in all pipelines** → **Save**

### 4D — Register a Self-Hosted Agent

Both pipelines target `pool: name: 'SelfHostedPool'`. You must register a Linux agent in a pool with that name.

**Create the pool first:**

1. **Project Settings** → **Agent pools** → **Add pool**
2. Type: **Self-hosted**, Name: `SelfHostedPool` → **Create**

**Install the agent on a Linux machine (Ubuntu 22.04 recommended):**

```bash
# Create a Personal Access Token (PAT) in Azure DevOps first:
# User Settings (top right avatar) → Personal access tokens → New Token
# Scopes: Agent Pools → Read & manage
# Copy the token value

# On your Linux agent machine:
mkdir ~/myagent && cd ~/myagent

curl -O https://vstsagentpackage.azureedge.net/agent/3.236.1/vsts-agent-linux-x64-3.236.1.tar.gz
tar zxvf vsts-agent-linux-x64-3.236.1.tar.gz

./config.sh \
  --url https://dev.azure.com/<YOUR_ORG> \
  --auth pat \
  --token <YOUR_PAT_TOKEN> \
  --pool SelfHostedPool \
  --agent MyLinuxAgent \
  --acceptTeeEula

# Install and start as a background service
sudo ./svc.sh install
sudo ./svc.sh start

# Verify it is running
sudo ./svc.sh status
```

Go to **Project Settings** → **Agent pools** → **SelfHostedPool** → **Agents** tab — you should see your agent with status **Online**.

---

## Phase 5 — Create and Run the Infra Pipeline

1. **Pipelines** → **New pipeline**
2. **Where is your code?** → Azure Repos Git
3. Select repository: `infra-epicbook`
4. **Configure your pipeline** → Existing Azure Pipelines YAML file
5. Branch: `main`, Path: `/infra-pipelines.yml` → **Continue**
6. Review the YAML → **Run**

### What the pipeline does

```
1.  Checkout infra-epicbook repo
2.  Download id_rsa.pub from Secure Files → ~/.ssh/id_rsa.pub
3.  apt install unzip curl
4.  Download Terraform 1.8.5 binary → /usr/local/bin/terraform
5.  Copy public key to ~/.ssh/
6.  terraform init   → connects to Azure blob backend
                        reads epicbook-prod.tfstate
7.  terraform plan   → calculates what Azure resources to create
                        saves plan to file 'tfplan'
8.  terraform apply  → creates in Azure:
                         Resource Group: epic-book-rg (Central India)
                         VNet: epicbook-prod-vnet (10.0.0.0/16)
                         Subnet web: 10.0.1.0/24
                         Subnet db:  10.0.2.0/24 (MySQL delegated)
                         NSG: allow TCP 22 + 80 inbound
                         Public IP: static, Standard SKU, zone 2
                         NIC: attached to web subnet + public IP
                         VM: Ubuntu 22.04 LTS, Standard_D2s_v3, zone 2
                         Private DNS zone for MySQL
                         MySQL Flexible Server: private, zone 2
                         Database: bookstore
9.  Read outputs:
      public_ip → VM's public IP address
      db_host   → MySQL FQDN
10. Write infra-outputs.env:
      vmPublicIp=<public IP>
      db_host=<mysql fqdn>
11. Publish 'infra-outputs' pipeline artifact
```

### Verify in Azure Portal

After the pipeline completes:

- Go to **Resource groups** → `epic-book-rg` → confirm all resources exist
- Note the **public IP address** from the pipeline logs (Terraform Apply step)

---

## Phase 6 — Create and Run the App Pipeline

1. **Pipelines** → **New pipeline**
2. **Where is your code?** → Azure Repos Git
3. Select repository: `theepicbook`
4. **Configure your pipeline** → Existing Azure Pipelines YAML file
5. Branch: `main`, Path: `/azure-pipelines.yml` → **Continue**
6. Review the YAML → **Save** (do not run manually the first time — it auto-triggers after the infra pipeline)

For your first run, click **Run pipeline** manually.

### What the pipeline does

```
1.  Checkout theepicbook repo (Ansible code)
2.  Download 'infra-outputs' artifact from the infra pipeline
3.  Source infra-outputs.env → set pipeline variables:
      vmPublicIp = <VM public IP>
      db_host    = <MySQL FQDN>
4.  Download id_rsa from Secure Files
5.  apt install ansible sshpass
6.  Copy id_rsa to ~/.ssh/ with chmod 600
7.  Generate inventory.ini dynamically:
      [web]
      <vmPublicIp>
      [web:vars]
      ansible_user=azureuser
      ansible_ssh_private_key_file=~/.ssh/id_rsa
8.  ansible all -m ping  → verify SSH connectivity to VM
9.  ansible-playbook site.yml -e "db_host=..." -e "db_password=..."
```

### What Ansible does on the VM

**Role: common**
```
- Create /tmp/ansible-tmp directory
- apt update
- Remove conflicting nodejs/npm packages (clean slate)
- Install: git, curl, unzip, acl, python3-mysqldb, python3-pymysql
- Add NodeSource repo → install Node.js 20 (npm included)
- Create /var/www, /var/www/.pm2, /var/www/.ansible/tmp (owned by www-data)
- Harden SSH: disable root login, disable password auth (key-only)
```

**Role: nginx**
```
- apt install nginx
- Deploy reverse proxy config to /etc/nginx/sites-available/epicbook:
    server {
        listen 80;
        location / { proxy_pass http://localhost:3000; }
    }
- Enable site, remove default site
- Start + enable nginx on boot
```

**Role: epicbook**
```
- Create /var/www/epicbook (owned by www-data)
- git clone https://github.com/pravinmishraaws/theepicbook → /var/www/epicbook
- apt install mysql-client
- Check if DB is already seeded → if not:
    run BuyTheBook_Schema.sql (create tables)
    run author_seed.sql      (seed authors)
    run books_seed.sql       (seed books)
- rm -rf node_modules, package-lock.json
- npm install (as www-data, HOME=/var/www)
- Write /var/www/epicbook/.env:
    PORT=3000
    DB_HOST=<mysql fqdn>
    DB_USER=epicbook_user
    DB_PASSWORD=<secret>
    DB_NAME=bookstore
- Write /var/www/epicbook/config/config.json (Sequelize + SSL)
- npm install -g pm2
- pm2 start server.js --name epicbook
- pm2 save + pm2 startup (survives VM reboots)
```

**Final step:**
```
curl -I http://<vmPublicIp>     → must return HTTP 200
curl http://<vmPublicIp> | head → must show EpicBook HTML
```

---

## Phase 7 — Verify End-to-End

### In the browser

Open:
```
http://<vmPublicIp>
```

You should see the EpicBook storefront with books listed.

### SSH into the VM

```bash
ssh -i ~/.ssh/id_rsa azureuser@<vmPublicIp>
```

**Check Nginx:**
```bash
sudo systemctl status nginx
sudo nginx -t
```

**Check the Node.js app process:**
```bash
sudo -u www-data PM2_HOME=/var/www/.pm2 pm2 list
sudo -u www-data PM2_HOME=/var/www/.pm2 pm2 logs epicbook --lines 50
```

**Check MySQL connectivity from the VM:**
```bash
mysql -h <mysql-fqdn> \
      -u epicbook_user \
      --ssl-mode=REQUIRED \
      -p bookstore
# enter your db_password when prompted
show tables;
```

**Check the app environment file:**
```bash
sudo cat /var/www/epicbook/.env
```

---

## Automatic Trigger Flow (After Initial Setup)

Once both pipelines exist, subsequent deployments are fully automatic:

```
Push Terraform change to infra-epicbook/main
           |
           v
   Infra pipeline triggers
   Terraform updates Azure resources
   Publishes new infra-outputs artifact
           |
           v (resources.pipelines trigger)
   App pipeline triggers
   Ansible reconfigures VM with new values
   curl verifies site is live
```

To trigger the app pipeline independently (e.g. after an application code change):
1. Push a change to `theepicbook/main`
2. Manually run the app pipeline and input `vmPublicIp` and `db_host` as variables, or re-run from the last successful infra artifact

---

## Names That Must Match Exactly

Mismatches here cause pipeline failures with confusing error messages.

| Item | Exact Value |
|---|---|
| Service connection name | `azure-devops-connection` |
| Variable group name | `epicbook-secrets` |
| Secret variable name | `db_password` |
| Secure file — public key | `id_rsa.pub` |
| Secure file — private key | `id_rsa` |
| Agent pool name | `SelfHostedPool` |
| Infra pipeline artifact name | `infra-outputs` |
| Artifact env file name | `infra-outputs.env` |
| App pipeline source reference | `infra-epicbook.git` |
| App repo name in Azure DevOps | `theepicbook` |
| Terraform backend RG | `rg-tfstate` |
| Terraform backend storage account | `epicbooktfstate01` |
| Terraform backend container | `tfstate` |
| Terraform state key | `epicbook-prod.tfstate` |

---

## Troubleshooting

### Terraform init fails — "storage account not found"

The backend storage account does not exist. Re-run Phase 1 commands to create it.

### Terraform apply fails — "PublicIPAddressCannotBeAssociated zone mismatch"

The VM is in zone 2 but the public IP was not created in zone 2. The code already sets `zones = ["2"]` on the public IP. If you are seeing this on an existing deployment, the existing public IP was created without a zone — destroy and recreate: `terraform destroy -target azurerm_public_ip.main`.

### Ansible ping fails — "SSH connection refused"

- Check that NSG allows port 22 inbound (already configured in `main.tf`)
- Verify the VM is running in Azure Portal
- Confirm `id_rsa` (private key) matches the `id_rsa.pub` that Terraform placed on the VM

### Ansible playbook fails — "mysql command not found"

The `epicbook` role installs `mysql-client` — if this step failed, re-run the pipeline. Alternatively SSH into the VM and run `sudo apt install mysql-client -y`.

### PM2 crashes after start — "Cannot find module"

npm install likely failed. SSH into the VM and check:
```bash
sudo -u www-data PM2_HOME=/var/www/.pm2 pm2 logs epicbook --lines 100
cd /var/www/epicbook && ls node_modules
```

### App returns 502 Bad Gateway

Nginx is running but Node.js is not. Check pm2:
```bash
sudo -u www-data PM2_HOME=/var/www/.pm2 pm2 list
sudo -u www-data PM2_HOME=/var/www/.pm2 pm2 restart epicbook
```

### Pipeline says "no hosted agents available"

Both pipelines use `SelfHostedPool`. Confirm your agent is **Online** in Project Settings → Agent pools → SelfHostedPool → Agents.

---

## Cost Estimate (Central India)

| Resource | Approx Monthly Cost |
|---|---|
| Standard_D2s_v3 VM | ~$70 USD |
| MySQL B_Standard_B1ms | ~$13 USD |
| Public IP (Standard) | ~$3 USD |
| Storage (Terraform state) | < $1 USD |
| **Total** | **~$87 USD/month** |

Stop the VM when not in use to reduce costs:
```bash
az vm deallocate --resource-group epic-book-rg --name epicbook-prod-vm
```

Start it again:
```bash
az vm start --resource-group epic-book-rg --name epicbook-prod-vm
```

---

## Clean Up (Destroy Everything)

To remove all Azure resources created by Terraform:

```bash
cd infra-epicbook

export ARM_CLIENT_ID="<CLIENT_ID>"
export ARM_CLIENT_SECRET="<CLIENT_SECRET>"
export ARM_TENANT_ID="<TENANT_ID>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export TF_VAR_db_password="<db_password>"

terraform init
terraform destroy -auto-approve
```

Then delete the state backend if you no longer need it:
```bash
az group delete --name rg-tfstate --yes --no-wait
```
