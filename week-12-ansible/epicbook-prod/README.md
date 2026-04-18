# EpicBook — Production Deployment on Azure

> Full-stack Node.js bookstore application deployed on Azure using **Terraform** for infrastructure provisioning and **Ansible roles** for configuration management and deployment.

---

## Live Demo

The EpicBook bookstore runs at `http://<public_ip>` after deployment — browse books, view authors, and manage a cart backed by Azure MySQL Flexible Server.

---

## Architecture

```
                        ┌─────────────────────────────┐
                        │        Azure Cloud           │
                        │                              │
  Browser               │  ┌──────────────────────┐   │
  http://<public_ip> ───┼─►│   Ubuntu 22.04 VM    │   │
                        │  │   Standard_B1s        │   │
                        │  │                       │   │
                        │  │  nginx (port 80)      │   │
                        │  │    ↓ proxy_pass       │   │
                        │  │  PM2 → server.js      │   │
                        │  │  (port 8080)          │   │
                        │  └──────────┬────────────┘   │
                        │             │ Sequelize       │
                        │             ↓                 │
                        │  ┌──────────────────────┐    │
                        │  │ Azure MySQL Flexible  │    │
                        │  │ Server               │    │
                        │  │ bookstore database   │    │
                        │  └──────────────────────┘    │
                        └─────────────────────────────┘
```

### Infrastructure (Terraform)
| Resource | Name | Details |
|---|---|---|
| Resource Group | rg-epicbook | Central India |
| Virtual Network | vnet-epicbook | 10.0.0.0/16 |
| Subnet | subnet-epicbook | 10.0.1.0/24 |
| NSG | nsg-epicbook | Allow SSH (22) + HTTP (80) |
| Public IP | pip-epicbook | Static, Standard SKU |
| Virtual Machine | vm-epicbook | Standard_B1s, Ubuntu 22.04 LTS |
| MySQL Server | epicbook-mysql | Flexible Server, B_Standard_B1ms |
| MySQL Database | bookstore | utf8mb4 |

### Application Stack
| Layer | Technology |
|---|---|
| Runtime | Node.js 18 |
| Framework | Express + Handlebars |
| ORM | Sequelize + mysql2 |
| Process Manager | PM2 (ecosystem.config.js) |
| Web Server | nginx (reverse proxy) |
| Database | Azure MySQL Flexible Server |

---

## Project Structure

```
epicbook-prod/
├── terraform/
│   └── azure/
│       ├── providers.tf          # Azure provider + Terraform version
│       └── main.tf               # All Azure resources + outputs
├── ansible/
│   ├── inventory.ini             # [web] group + SSH variables
│   ├── site.yml                  # Role orchestration: common → nginx → epicbook
│   ├── group_vars/
│   │   └── web.yml               # App + DB variables (no hardcoding in roles)
│   └── roles/
│       ├── common/
│       │   ├── tasks/main.yml    # Node.js 18, PM2, mysql-client, SSH hardening
│       │   └── handlers/main.yml # Restart sshd
│       ├── nginx/
│       │   ├── tasks/main.yml    # Install, configure, enable, remove default
│       │   ├── handlers/main.yml # Reload nginx
│       │   └── templates/
│       │       └── epicbook.conf.j2  # Jinja2 reverse proxy config
│       └── epicbook/
│           ├── tasks/main.yml    # Clone, config, npm install, seed DB, PM2
│           └── handlers/main.yml # Reload nginx
└── README.md
```

---

## Prerequisites

- Azure CLI authenticated (`az login`)
- Terraform >= 1.0 installed
- Python 3.9+ with venv
- SSH ed25519 key at `~/.ssh/id_ed25519`
- Ansible installed inside a venv (`pip install ansible ansible-lint`)

---

## Deployment Guide

### Step 1 — Clone This Repo

```bash
git clone <repo-url>
cd epicbook-prod
```

### Step 2 — Provision Infrastructure

```bash
cd terraform/azure
terraform init
terraform plan
terraform apply
```

Note the outputs:
```
public_ip      = "xx.xx.xx.xx"
admin_user     = "azureuser"
mysql_host     = "epicbook-mysql.mysql.database.azure.com"
mysql_user     = "epicbookadmin"
mysql_database = "bookstore"
```

### Step 3 — Update Ansible Config

Edit `ansible/inventory.ini` — replace with your `public_ip`:
```ini
[web]
xx.xx.xx.xx

[web:vars]
ansible_user=azureuser
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

Edit `ansible/group_vars/web.yml` — replace `db_host` with your `mysql_host`:
```yaml
db_host: "epicbook-mysql.mysql.database.azure.com"
```

### Step 4 — Verify SSH Access

```bash
ssh azureuser@<public_ip> "hostname"
# Expected: vm-epicbook
```

### Step 5 — Run the Playbook

```bash
cd ansible/
source ../.venv/bin/activate
ansible-playbook -i inventory.ini site.yml
```

### Step 6 — Verify

```bash
# Browser
http://<public_ip>

# Command line
curl -I http://<public_ip>
# Expected: HTTP/1.1 200 OK
```

---

## Ansible Role Summary

### `common`
- Updates apt cache and upgrades packages
- Installs Node.js 18 via NodeSource
- Installs PM2 globally
- Installs `mysql-client` for DB seeding
- Hardens SSH — disables root login and password authentication

### `nginx`
- Installs nginx
- Deploys site config from Jinja2 template (`epicbook.conf.j2`)
- Enables the epicbook site via symlink
- Removes the default nginx site
- Reloads nginx when config changes via handler

### `epicbook`
- Marks app directory as git safe
- Clones `https://github.com/pravinmishraaws/theepicbook`
- Sets correct ownership (`azureuser`)
- Fixes config directory permissions
- Writes `config/config.json` with production DB credentials
- Runs `npm install`
- Seeds Azure MySQL with schema + author + books SQL files
- Writes `ecosystem.config.js` for PM2
- Kills any root PM2 daemon + frees the app port
- Starts app with PM2 as `azureuser` (no sudo)
- Saves PM2 process list and sets startup on boot

---

## group_vars Reference

```yaml
# ansible/group_vars/web.yml

app_repo:        https://github.com/pravinmishraaws/theepicbook
app_dest:        /var/www/epicbook
app_user:        azureuser
app_group:       azureuser
app_start_file:  server.js
app_port:        8080
nginx_site_name: epicbook

db_host:     "epicbook-mysql.mysql.database.azure.com"
db_user:     epicbookadmin
db_password: "YourPassword"
db_name:     bookstore
db_port:     3306
```

---

## Idempotency

Re-running the playbook on an unchanged server returns all `ok` with zero failed:

```bash
ansible-playbook -i inventory.ini site.yml

PLAY RECAP
xx.xx.xx.xx : ok=18  changed=0  unreachable=0  failed=0
```

---

## Teardown

```bash
cd terraform/azure
terraform destroy
# Type: yes
```

All Azure resources removed. Re-deploy from scratch anytime with the same two commands.

---

## Issues Encountered + Fixes

| Issue | Root Cause | Fix |
|---|---|---|
| Public IP quota error | Basic SKU limit reached | `sku = "Standard"` + `allocation_method = "Static"` |
| NSG not applying | Per-NIC association unreliable | Subnet-level association |
| `notify` inside module | Wrong YAML indentation | Moved to task level |
| git safe.directory error | Running as root via become | Shell task before clone |
| config.json permission denied | File owned by root | Explicit `file` task to fix ownership |
| MySQL SSL error | `require_secure_transport=ON` | Terraform config resource sets it OFF |
| Root PM2 conflict | Previous `sudo pm2 start` | `sudo pm2 kill` + `become: false` on all PM2 tasks |
| Port 8080 stuck | PM2 auto-restart under root | `sudo fuser -k 8080/tcp` + `wait_for` |

---

## Tech Stack

![Terraform](https://img.shields.io/badge/Terraform-623CE4?style=flat&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=flat&logo=nodedotjs&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat&logo=mysql&logoColor=white)
![nginx](https://img.shields.io/badge/nginx-009639?style=flat&logo=nginx&logoColor=white)

---

## Part of DevOps Micro Internship

This project is Week 12, Assignment 5 of the **DevOps Micro Internship** guided by [Pravin Mishra](https://github.com/pravinmishraaws).

---

*Venkatesh Gangavarapu — Senior DevOps Engineer*
