<div align="center">

# Week 10 — Assignment 3: React App on Azure VM

### DevOps Micro Internship · Venkatesh Gangavarapu

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Status](https://img.shields.io/badge/Assignment-Completed-22C55E?style=for-the-badge)

</div>

---

## 🎯 Objective

Provision an Azure VM using Terraform and deploy a React application on Ubuntu 20.04 — served by Nginx on port 80.

---

## 🏗️ Architecture

```
Browser ──────────────────────────────────► http://<public-ip>
                                                    │
                                    ┌───────────────▼──────────────┐
                                    │   Azure Public IP (Static)   │
                                    └───────────────┬──────────────┘
                                                    │
┌───────────────────────────────────────────────────▼──────────────────────┐
│                     Azure Resource Group: react-app-rg                   │
│                                                                           │
│  VNet (10.0.0.0/16) ──► Subnet (10.0.1.0/24) ──► NIC ──► NSG            │
│                                                    │                      │
│                         ┌──────────────────────────▼──────────────────┐  │
│                         │  Ubuntu 20.04 VM  (Standard_B1s)            │  │
│                         │  ├── Nginx ──► /var/www/html/ (React build) │  │
│                         │  ├── Node.js + npm (build tooling)          │  │
│                         │  └── NSG: SSH (22) + HTTP (80) open         │  │
│                         └─────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
Week-10-React-Azure/
├── README.md             ← This file
└── terraform/
    ├── main.tf           ← All 9 Azure resources
    ├── variables.tf      ← Input variables
    ├── outputs.tf        ← Public IP output
    └── provider.tf       ← AzureRM provider
```

---

## ⚙️ Terraform Resources (9 total)

| # | Resource | Purpose |
|---|---|---|
| 1 | `azurerm_resource_group` | Container: react-app-rg, East US |
| 2 | `azurerm_virtual_network` | VNet — 10.0.0.0/16 |
| 3 | `azurerm_subnet` | Subnet — 10.0.1.0/24 |
| 4 | `azurerm_network_security_group` | Allows SSH (22) + HTTP (80) |
| 5 | `azurerm_subnet_network_security_group_association` | NSG → Subnet |
| 6 | `azurerm_public_ip` | Static public IP |
| 7 | `azurerm_network_interface` | NIC — subnet + public IP |
| 8 | `azurerm_network_interface_security_group_association` | NSG → NIC |
| 9 | `azurerm_linux_virtual_machine` | Ubuntu 20.04, Standard_B1s |

---

## 🚀 Full Deployment Lifecycle

### Prerequisites
```bash
az login                   # Authenticate to Azure
az account show            # Verify subscription
terraform --version        # Confirm Terraform installed
```

### Step 1 — Provision Infrastructure
```bash
mkdir terraform-react-azure && cd terraform-react-azure
# Write main.tf (see terraform/ folder)

terraform init
terraform plan    # Review: 9 to add
terraform apply   # Type 'yes'
terraform output  # Note the public IP
```

### Step 2 — SSH into VM
```bash
ssh azureuser@<public-ip>
# Accept fingerprint — type 'yes'
```

### Step 3 — Install Dependencies
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nodejs npm git -y
node -v && npm -v    # Verify installed
```

### Step 4 — Clone and Build React App
```bash
git clone https://github.com/pravinmishraaws/my-react-app
cd my-react-app
npm install          # Install dependencies
npm run build        # Produces build/ directory
```

### Step 5 — Configure Nginx
```bash
sudo apt install nginx -y
sudo systemctl start nginx && sudo systemctl enable nginx

# Deploy React build to Nginx web root
sudo cp -r build/* /var/www/html/

# Fix React Router — edit Nginx config
sudo nano /etc/nginx/sites-available/default
# Inside location / block, change:
#   try_files $uri $uri/ =404;
# to:
#   try_files $uri $uri/ /index.html;

sudo nginx -t                    # Test config
sudo systemctl reload nginx      # Apply changes
```

### Step 6 — Verify
```bash
# Open in browser:
http://<public-ip>
# ✅ React app homepage loads
# ✅ Navigation works
# ✅ Page refresh on sub-routes works (not 404)
```

### Step 7 — Destroy
```bash
terraform destroy    # Type 'yes'
# Destroy complete! Resources: 9 destroyed.
```

---

## 📤 Outputs

```
public_ip = "XX.XX.XX.XX"
```

---

## ✅ Tasks Completed

| Task | Description | Status |
|---|---|:---:|
| Task 1 | Provision VM with Terraform + deploy React via Nginx | ✅ |
| Task 2 | Verify React app in browser + navigation works | ✅ |
| Task 3 | Submit screenshots + summary | ✅ |

---

## 💡 Key Learnings

**1. React SPA routing requires Nginx `try_files` config.**
Without `try_files $uri $uri/ /index.html`, refreshing any route other than `/` returns 404.
Nginx looks for physical files — React Router handles routing in the browser.

**2. `npm run build` produces a fully static output.**
No Node.js server needed in production. Nginx serves plain HTML/CSS/JS.
The `build/` folder is what gets deployed — not the source code.

**3. This assignment combined 3 internship skills in one pipeline.**
Terraform (Week 10) + SSH/Linux (Week 1) + application deployment = a complete real-world workflow.

---

## ⚠️ Issues & Solutions

| Issue | Root Cause | Fix |
|---|---|---|
| Blank page after deploy | Incomplete file copy (missing -r flag) | `sudo cp -r build/* /var/www/html/` |
| 404 on page refresh | Nginx doesn't know React Router routes | Add `try_files $uri $uri/ /index.html` |
| NIC association failed on destroy | Azure API timing | Re-run `terraform destroy` |

---

## 🔗 React App Source

[https://github.com/pravinmishraaws/my-react-app](https://github.com/pravinmishraaws/my-react-app)

---

## 🔗 Navigation

← [Assignment 2 — AWS EC2 in Custom VPC](../Week-10-Terraform-AWS/)
← [Assignment 1 — Azure VM](../Week-10-Terraform-Azure/)
→ Week 11 — Coming Soon

[↑ Back to Main README](../README.md)

---

<div align="center">
<sub>DevOps Micro Internship · Week 10 · Assignment 3 · React on Azure · Venkatesh Gangavarapu</sub>
</div>
