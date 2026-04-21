# Week 13 — Assignment 3: Multi-Stage CI/CD Pipeline for React App

> Azure DevOps multi-stage pipeline — Build → Test → Publish → Deploy — automating React application deployment to an Ubuntu VM running Nginx.

---

## What This Project Does

Every commit to `main` triggers a 4-stage pipeline in Azure DevOps:

```
Commit to main
      │
      ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Stage 1   │────►│   Stage 2   │────►│   Stage 3   │────►│   Stage 4   │
│    Build    │     │    Test     │     │   Publish   │     │   Deploy    │
│             │     │             │     │             │     │             │
│ npm install │     │ npm test    │     │ Store build │     │ SSH copy to │
│ npm run     │     │ CI=true     │     │ as artifact │     │ /var/www    │
│ build       │     │ no watch    │     │ in Azure DO │     │ restart     │
│             │     │             │     │             │     │ nginx       │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                    │
                                                                    ▼
                                                        http://<public_ip>
                                                        React app live
```

---

## Project Structure

```
week13-react-cicd/
├── terraform/
│   ├── providers.tf          # Azure provider
│   └── main.tf               # VM + networking + outputs
├── ansible/
│   ├── inventory.ini         # Target VM
│   └── site.yml              # Install nginx + configure web root
├── azure-pipelines/
│   └── azure-pipelines.yml   # Full 4-stage pipeline YAML
├── .gitignore
└── README.md
```

> The React source code lives in a separate Azure Repos project (`my-react-app`) imported from GitHub. The pipeline YAML in this repo is committed alongside it.

---

## Prerequisites

- Azure CLI authenticated (`az login`)
- Terraform >= 1.0 installed
- Python 3.9+ with venv + Ansible installed
- SSH ed25519 key at `~/.ssh/id_ed25519`
- Azure DevOps organization with a project
- Self-hosted agent registered under `SelfHostedPool` (from Assignment 1)
- SSH Service Connection `ubuntu-nginx-ssh` configured in Azure DevOps

---

## Part 1 — Infrastructure (Terraform)

### Provision the VM

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

Outputs:
```
public_ip  = "xx.xx.xx.xx"
admin_user = "azureuser"
```

---

## Part 2 — Configuration (Ansible)

### Install Nginx + Configure Web Root

Update `ansible/inventory.ini` with your VM public IP, then run:

```bash
cd ansible/
source ../.venv/bin/activate
ansible-playbook -i inventory.ini site.yml
```

This installs nginx, sets up `/var/www/html`, and enables password authentication for the SSH Service Connection.

---

## Part 3 — Azure DevOps Setup

### Step 1 — Import React App Repo

In Azure DevOps → Repos → Import repository:
- URL: `https://github.com/pravinmishraaws/my-react-app`
- Name: `my-react-app`

### Step 2 — Create SSH Service Connection

Project Settings → Service Connections → New → SSH:
- Name: `ubuntu-nginx-ssh`
- Host: `<public_ip>`
- Port: `22`
- Username: `azureuser`
- Password: `<set during Ansible run>`

### Step 3 — Create Pipeline

Pipelines → New Pipeline → Azure Repos Git → `my-react-app` → paste `azure-pipelines/azure-pipelines.yml`

---

## Part 4 — Verify

```bash
# After pipeline completes
curl -I http://<public_ip>
# Expected: HTTP/1.1 200 OK

# Open in browser
http://<public_ip>
# React app should load
```

---

## Pipeline Stage Summary

| Stage | Pool | Key Steps | Output |
|---|---|---|---|
| Build | SelfHostedPool | npm install, npm run build | `react_build` artifact |
| Test | SelfHostedPool | npm test --watchAll=false | Pass / Fail |
| Publish | SelfHostedPool | Download + verify artifact | Confirmed |
| Deploy | SelfHostedPool | SSH copy, fix perms, restart nginx | Live site |

---

## Why Artifact Publish/Download?

Each stage runs as an independent job. The `build/` directory created in Stage 1 lives only on that job's workspace. Publishing it as an artifact stores it in Azure DevOps so Stage 4 (Deploy) can download it even though it runs in a different job context.

```
Stage 1 (Build)  → publish: build/ → stored as react_build in Azure DevOps
Stage 4 (Deploy) → download: react_build → available at $(Pipeline.Workspace)/react_build
```

Without publish/download, Deploy has no access to the built files.

---

## Issues + Fixes

| Issue | Cause | Fix |
|---|---|---|
| `NodeTool@0` fails | Node.js not on agent VM | Install Node.js 18 via NodeSource on the VM |
| Tests fail `ENOSPC` | inotify watch limit | `echo fs.inotify.max_user_watches=524288 \| sudo tee -a /etc/sysctl.conf` |
| Blank page after deploy | nginx missing SPA routing | Add `try_files $uri /index.html` to nginx config |
| Deploy stage skipped | Earlier stage failed | Fix failing stage — `dependsOn` blocks the chain |
| SSH copy copies nothing | Wrong artifact path | Use `$(Pipeline.Workspace)/react_build` not `Build.SourcesDirectory` |

---

## Teardown

```bash
cd terraform/
terraform destroy
```

---

## Part of DevOps Micro Internship

Week 13, Assignment 3 — **DevOps Micro Internship** guided by [Pravin Mishra](https://github.com/pravinmishraaws).

---

*Venkatesh Gangavarapu — Senior DevOps Engineer*
