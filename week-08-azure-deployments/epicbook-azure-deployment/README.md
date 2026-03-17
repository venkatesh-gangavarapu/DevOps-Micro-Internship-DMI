# 📚 EpicBook — Full Stack Deployment on Azure

![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=for-the-badge&logo=node.js&logoColor=white)
![MySQL](https://img.shields.io/badge/Azure_MySQL-Flexible_Server-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-Reverse_Proxy-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Status](https://img.shields.io/badge/Status-Deployed-success?style=for-the-badge)

> **Week 8 — Assignment 3** | DevOps Micro Internship by Pravin Mishra  
> Deployed the EpicBook bookstore web application on Azure using a Virtual Machine, NGINX reverse proxy, Node.js/Express backend, and Azure MySQL Flexible Server with private VNet integration.

---

## 🏗️ Architecture Overview

```
                         ┌──────────────────────────────┐
                         │       INTERNET (Users)        │
                         └──────────────┬───────────────┘
                                        │ HTTP (Port 80)
                                        ▼
                         ┌──────────────────────────────┐
                         │        Public IP              │
                         │      epicbook-vm-pip          │
                         └──────────────┬───────────────┘
                                        │
                    ┌───────────────────▼──────────────────────┐
                    │         epicbook-vnet  10.0.0.0/16        │
                    │                                           │
                    │   ┌───────────────────────────────────┐   │
                    │   │    Public Subnet  10.0.1.0/24     │   │
                    │   │    NSG: Allow SSH(22), HTTP(80)   │   │
                    │   │                                   │   │
                    │   │   ┌─────────────────────────┐    │   │
                    │   │   │      epicbook-vm         │    │   │
                    │   │   │   Ubuntu 22.04 LTS       │    │   │
                    │   │   │                          │    │   │
                    │   │   │  NGINX (port 80)         │    │   │
                    │   │   │     ↓ proxy_pass         │    │   │
                    │   │   │  Node.js (port 8080)     │    │   │
                    │   │   │  PM2 Process Manager     │    │   │
                    │   │   └──────────┬──────────────┘    │   │
                    │   └─────────────┼─────────────────────┘   │
                    │                 │ Port 3306 (MySQL)        │
                    │   ┌─────────────▼─────────────────────┐   │
                    │   │   Private Subnet  10.0.2.0/24     │   │
                    │   │   NSG: Allow MySQL(3306)          │   │
                    │   │        from 10.0.1.0/24 only      │   │
                    │   │                                   │   │
                    │   │   ┌─────────────────────────┐    │   │
                    │   │   │   Azure MySQL Flexible   │    │   │
                    │   │   │       Server             │    │   │
                    │   │   │  Private Access (VNet)   │    │   │
                    │   │   │  No public internet      │    │   │
                    │   │   │  access — ever           │    │   │
                    │   │   └─────────────────────────┘    │   │
                    │   └───────────────────────────────────┘   │
                    └───────────────────────────────────────────┘
```

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Tech Stack](#-tech-stack)
- [IP Planning](#-ip-planning)
- [Tasks Completed](#-tasks-completed)
- [Task 1 — Network Infrastructure](#task-1--network-infrastructure)
- [Task 2 — Virtual Machine](#task-2--virtual-machine)
- [Task 3 — Application Deployment](#task-3--application-deployment)
- [Task 4 — Azure MySQL Setup](#task-4--azure-mysql-setup)
- [Real Issues Faced + Fixes](#-real-issues-faced--fixes)
- [Key Learnings](#-key-learnings)
- [Screenshots](#-screenshots)
- [Cleanup](#-cleanup)

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Cloud | Microsoft Azure | Infrastructure platform |
| Networking | Azure VNet + Subnets | Private network isolation |
| Security | Network Security Groups | Firewall rules per subnet |
| Compute | Azure VM (Ubuntu 22.04) | Application host |
| Web Server | NGINX | Reverse proxy on port 80 |
| Runtime | Node.js + Express | Application backend |
| Templating | Handlebars (HBS) | Server-side HTML rendering |
| ORM | Sequelize + mysql2 | Database abstraction layer |
| Database | Azure MySQL Flexible Server | Managed relational database |
| Process Manager | PM2 | Node.js persistence + auto-restart |

---

## 🗺️ IP Planning

| Resource | Value | Purpose |
|---|---|---|
| Virtual Network | `10.0.0.0/16` | Full private address space |
| Public Subnet | `10.0.1.0/24` | VM — internet-facing tier |
| Private Subnet | `10.0.2.0/24` | MySQL — no internet access |
| VM Private IP | `10.0.1.x` (dynamic) | Internal VM address |
| MySQL Private IP | `10.0.2.x` (managed) | Internal DB address |

---

## ✅ Tasks Completed

- [x] **Task 1** — VNet, subnets, NSGs, Public IP, NIC
- [x] **Task 2** — Ubuntu VM provisioned with Node.js, NGINX, Git, mysql-client
- [x] **Task 3** — EpicBook cloned, dependencies installed, NGINX + PM2 configured
- [x] **Task 4** — Azure MySQL Flexible Server with private VNet integration

---

## Task 1 — Network Infrastructure

### Virtual Network

```
Name   : epicbook-vnet
CIDR   : 10.0.0.0/16
Region : East US
```

### Subnets

```
public-subnet   → 10.0.1.0/24   (VM lives here)
private-subnet  → 10.0.2.0/24   (MySQL lives here)
```

### NSG — Public Subnet (public-nsg)

| Rule Name | Port | Protocol | Source | Action |
|---|---|---|---|---|
| Allow-SSH | 22 | TCP | Any | Allow |
| Allow-HTTP | 80 | TCP | Any | Allow |

### NSG — Private Subnet (private-nsg)

| Rule Name | Port | Protocol | Source | Action |
|---|---|---|---|---|
| Allow-MySQL-From-VM | 3306 | TCP | `10.0.1.0/24` only | Allow |

> **Security Design:** MySQL port 3306 is only reachable from the VM's subnet IP range. The internet, other subnets, and other services cannot reach the database — even though it's in the same VNet.

### Additional Resources

```
Public IP  : epicbook-vm-pip  (Static, Standard SKU)
NIC        : epicbook-vm-nic  (attached to public-subnet + public IP)
```

---

## Task 2 — Virtual Machine

```
Name     : epicbook-vm
Image    : Ubuntu Server 22.04 LTS
Size     : Standard_B1s
Subnet   : public-subnet (10.0.1.0/24)
Public IP: epicbook-vm-pip (Static)
Auth     : Username + Password
```

### Software Installation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install all required packages
sudo apt install nodejs npm nginx git mysql-client -y

# Upgrade Node.js to v18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Enable NGINX on boot
sudo systemctl enable nginx
sudo systemctl start nginx
```

### Verified Versions

```bash
node -v        # v18.x.x
npm -v         # 9.x.x
nginx -v       # nginx/1.18.x
git --version  # git version 2.x.x
mysql --version # mysql Ver 8.x.x
```

---

## Task 3 — Application Deployment

### About EpicBook

After cloning and reading `package.json`, the actual stack was identified:

```json
{
  "main": "server.js",
  "scripts": { "start": "node server.js" },
  "dependencies": {
    "express": "^4.17.1",
    "express-handlebars": "^5.0.0",
    "sequelize": "^6.3.0",
    "mysql2": "^2.1.0"
  }
}
```

> ⚠️ **Important Discovery:** The assignment described a React app requiring `npm run build`. The actual codebase is an **Express + Handlebars MVC application** — server-side rendering, no build step. This was identified by reading `package.json` before running any commands.

### Clone and Install

```bash
cd ~
git clone https://github.com/pravinmishraaws/theepicbook.git
cd theepicbook
npm install
```

### NGINX Configuration (Reverse Proxy)

```bash
sudo nano /etc/nginx/sites-available/epicbook
```

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;     # app runs on 8080
        proxy_http_version 1.1;
        proxy_set_header Upgrade        $http_upgrade;
        proxy_set_header Connection     'upgrade';
        proxy_set_header Host           $host;
        proxy_set_header X-Real-IP      $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/epicbook /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

### PM2 Process Manager

```bash
sudo npm install -g pm2
pm2 start server.js --name "epicbook"
pm2 save
pm2 startup
```

---

## Task 4 — Azure MySQL Setup

### Server Configuration

```
Name               : epicbook-mysql
Version            : MySQL 8.0
Tier               : Burstable (Standard_B1ms)
Connectivity       : Private access (VNet Integration)
Subnet             : private-subnet (10.0.2.0/24)
Private DNS Zone   : epicbook.mysql.database.azure.com
Public Access      : Disabled — no internet exposure
```

### Database Setup via mysql-client

```bash
# Connect from VM
mysql -h epicbook-mysql.mysql.database.azure.com \
      -u epicbookadmin -p

# Inside MySQL shell
CREATE DATABASE epicbook;
USE epicbook;
SHOW TABLES;
```

### Sequelize Config (config/config.json)

```json
{
  "development": {
    "username": "epicbookadmin",
    "password": "<password>",
    "database": "epicbook",
    "host": "epicbook-mysql.mysql.database.azure.com",
    "port": 3306,
    "dialect": "mysql",
    "dialectOptions": {
      "ssl": {
        "require": true,
        "rejectUnauthorized": false
      }
    }
  }
}
```

---

## 🔥 Real Issues Faced + Fixes

This section documents actual problems encountered during deployment — not a perfect run.

---

### Issue 1 — MySQL Region Not Available

**Error:**
```
ProvisionNotSupportedForRegion: Provisioning in requested 
region is not supported.
```

**Root Cause:**  
Azure MySQL Flexible Server is not available in Central India under free tier subscriptions.

**Fix:**  
Deleted and recreated all resources in **East US** region. Since MySQL requires VNet integration in the same region, the entire infrastructure (VNet, VM, MySQL) was moved together.

**Lesson:**  
Always verify regional service availability before designing your architecture. Azure's free tier has regional capacity restrictions.

---

### Issue 2 — 502 Bad Gateway (Wrong Port)

**Error:**  
Browser showed `502 Bad Gateway` after NGINX was configured.

**Root Cause:**  
NGINX was configured to proxy to `localhost:3000`. Reading `server.js` revealed:
```javascript
const PORT = process.env.PORT || 8080;  // app runs on 8080
```

**Fix:**  
Updated `proxy_pass` in NGINX config from `:3000` to `:8080`.

**Lesson:**  
Always read the application source code before writing infrastructure config. Never assume default ports.

---

### Issue 3 — Sequelize Connecting to Localhost

**Error:**
```
SequelizeConnectionRefusedError: connect ECONNREFUSED 127.0.0.1:3306
```

**Root Cause:**  
The app was reading `config/config.json` which had hardcoded `"host": "127.0.0.1"`. The `.env` file was not being used by Sequelize.

**Fix:**  
Updated `config/config.json` directly with Azure MySQL hostname and credentials.

**Lesson:**  
In real deployments, always trace how the application reads its configuration — env files, config.json, or hardcoded values. They are not always the same.

---

### Issue 4 — SSL Transport Rejection

**Error:**
```
Connections using insecure transport are prohibited 
while --require_secure_transport=ON
```

**Root Cause:**  
Azure MySQL Flexible Server enforces SSL by default. Sequelize was connecting without SSL.

**Fix:**  
Set `require_secure_transport = OFF` in Azure MySQL Server Parameters for the learning environment. For production, the correct fix is adding SSL dialect options in Sequelize config.

**Lesson:**  
Managed cloud databases have security defaults that self-hosted databases do not. Always check SSL requirements when connecting to managed services.

---

## 💡 Key Learnings

1. **Read the code before writing infrastructure** — The assignment described a React app. The actual codebase was Express + Handlebars. Reading `package.json` saved time and prevented wrong commands.

2. **Logs are your best debugging tool** — Every issue was identified by reading `pm2 logs`, not by guessing. The log told us the exact error, exact file, and exact line.

3. **Private DNS Zone is what makes VNet integration work** — Without it, the MySQL hostname resolves to a public IP. With it, it resolves to a private IP inside your VNet. That's the difference between secure and exposed.

4. **Managed databases have security defaults** — Azure MySQL enforces SSL, requires strong passwords, and restricts transport. These are features, not obstacles.

5. **NSG rules at subnet level vs NIC level** — Applying NSG to the subnet protects all resources in it, not just one VM. This is the correct production approach.

6. **PM2 is mandatory for Node.js in production** — Without it, the app dies the moment you disconnect SSH. PM2 keeps it running and restarts it automatically on crashes or reboots.

---


## 🧹 Cleanup

```bash
Azure Portal → Resource Groups → epicbook-rg
→ Delete resource group
→ Type: epicbook-rg → Confirm
```

Removes all resources at once:
- ✅ Virtual Network + Subnets
- ✅ NSGs
- ✅ Virtual Machine + NIC + Disks
- ✅ Public IP
- ✅ Azure MySQL Flexible Server
- ✅ Private DNS Zone

---
*Built with 💙 on Microsoft Azure | DevOps Micro Internship — Week 8, Assignment 3*
