# 🏗️ Three-Tier Network Architecture on Azure

![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-Web_Server-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

> **Week 8 Assignment** — DevOps Micro Internship by Pravin Mishra  
> Designed and deployed a production-grade Three-Tier Network Architecture on Microsoft Azure using VNets, Subnets, Virtual Machines, NGINX, and a Public Load Balancer.

---

## 📐 Architecture Overview

```
                        ┌─────────────────────────────────────┐
                        │         INTERNET (Users)            │
                        └──────────────┬──────────────────────┘
                                       │
                                       ▼
                        ┌─────────────────────────────────────┐
                        │      Public Load Balancer           │
                        │         web-public-elb              │
                        │   Frontend IP: web-elb-ip (Static)  │
                        │   Health Probe: TCP:80 every 5s     │
                        └──────────────┬──────────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                                     │
                    ▼                                     ▼
       ┌────────────────────────┐           ┌────────────────────────┐
       │     web-nginx (VM1)    │           │   web-nginx-2 (VM2)    │
       │   Ubuntu 22.04 LTS     │           │   Ubuntu 22.04 LTS     │
       │   NGINX Web Server     │           │   NGINX Web Server     │
       └────────────────────────┘           └────────────────────────┘
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │        eb-demo-vnet                  │
                    │        CIDR: 10.0.0.0/16             │
                    │                                      │
                    │  ┌─────────────────────────────────┐ │
                    │  │  web-subnet   10.0.1.0/24  🌐   │ │
                    │  ├─────────────────────────────────┤ │
                    │  │  app-subnet   10.0.2.0/25  🔒   │ │
                    │  ├─────────────────────────────────┤ │
                    │  │  db-subnet    10.0.3.0/26  🔐   │ │
                    │  ├─────────────────────────────────┤ │
                    │  │  AzureBastionSubnet        🛡️   │ │
                    │  └─────────────────────────────────┘ │
                    └──────────────────────────────────────┘
```

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [IP Planning](#-ip-planning)
- [Tech Stack](#-tech-stack)
- [Tasks Completed](#-tasks-completed)
- [Step-by-Step Implementation](#-step-by-step-implementation)
- [Load Balancer Configuration](#-load-balancer-configuration)
- [Testing & Validation](#-testing--validation)
- [Key Learnings](#-key-learnings)
- [Cleanup](#-cleanup)

---

## 🗺️ IP Planning

| Resource | CIDR / Value | Usable IPs | Purpose |
|---|---|---|---|
| Virtual Network | `10.0.0.0/16` | 65,531 | Full private address space |
| web-subnet | `10.0.1.0/24` | 251 | Public-facing web VMs |
| app-subnet | `10.0.2.0/25` | 123 | Internal application tier |
| db-subnet | `10.0.3.0/26` | 59 | Database tier (smallest) |
| AzureBastionSubnet | `10.0.4.0/26` | Auto | Secure VM access |

> **Why smaller subnets for deeper tiers?**  
> Fewer DB servers than web servers → smaller CIDR = reduced attack surface. This is deliberate security design.

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Microsoft Azure | Cloud Platform |
| Azure VNet | Private Network |
| Azure Subnets | Network Segmentation |
| Azure Virtual Machines | Compute (Ubuntu 22.04 LTS) |
| NGINX | Web Server |
| Azure Public Load Balancer (Standard) | Traffic Distribution |
| Azure Bastion | Secure SSH without Public IP |
| Network Security Groups (NSG) | Firewall Rules |

---

## ✅ Tasks Completed

- [x] **Task 1** — Created Resource Group `vnet-demo-rg` in Central India
- [x] **Task 2** — Created VNet `eb-demo-vnet` with 3 subnets + Azure Bastion
- [x] **Task 3** — Deployed `web-nginx` VM inside `web-subnet`
- [x] **Task 4** — Installed and configured NGINX with custom HTML page
- [x] **Task 5** — Created Public Load Balancer with Backend Pool, Health Probe, and LB Rules
- [x] **Task 6** — Tested architecture end-to-end via Load Balancer public IP
- [x] **Task 7** — Cleaned up all resources to avoid charges

---

## 📖 Step-by-Step Implementation

### Task 1 — Resource Group

```
Name   : vnet-demo-rg
Region : Central India
```

A Resource Group acts as a logical container for all project resources. Placing everything in one group enables single-action cleanup — deleting the group removes all resources simultaneously.

---

### Task 2 — Virtual Network + Subnets

```
VNet Name : eb-demo-vnet
CIDR      : 10.0.0.0/16
Region    : Central India
```

Created three subnets following the three-tier security model:

```bash
web-subnet  → 10.0.1.0/24   # Internet-facing
app-subnet  → 10.0.2.0/25   # Internal only
db-subnet   → 10.0.3.0/26   # Most restricted
```

Also enabled **Azure Bastion** for secure browser-based SSH access without exposing port 22 to the internet.

---

### Task 3 — Virtual Machine Deployment

```
VM Name        : web-nginx
Image          : Ubuntu Server 22.04 LTS
Size           : Standard_B1s
Subnet         : web-subnet (10.0.1.0/24)
Public IP      : web-nginx-pip
Inbound Ports  : SSH (22), HTTP (80)
Auth           : Username + Password
```

---

### Task 4 — NGINX Installation

SSH into the VM and run:

```bash
# Update package list
sudo apt update

# Install NGINX
sudo apt install -y nginx

# Enable NGINX to start on reboot
sudo systemctl enable nginx

# Start NGINX now
sudo systemctl start nginx

# Verify status
sudo systemctl status nginx
```

Created a custom HTML page to identify traffic source during Load Balancer testing:

```bash
sudo nano /var/www/html/index.html
```

```html
<!DOCTYPE html>
<html>
<head><title>Web Server - VM1</title></head>
<body>
    <h1>🚀 web-nginx — VM 1</h1>
    <p>Three-Tier Architecture on Azure</p>
    <p>Served from: web-subnet | 10.0.1.x</p>
</body>
</html>
```

Validate NGINX config:

```bash
sudo nginx -t
# nginx: configuration file syntax is ok ✅
```

---

## ⚖️ Load Balancer Configuration

### Overview

| Component | Name | Value |
|---|---|---|
| Load Balancer | `web-public-elb` | Standard, Public |
| Frontend IP | `web-elb-ip` | Static Public IP |
| Backend Pool | `web-backend-pool` | web-nginx VM |
| Health Probe | `web-health-probe` | TCP:80, every 5s |
| LB Rule | `web-http-rule` | Port 80 → 80 |

### How the Load Balancer Works

```
Every 5 seconds → Health Probe pings TCP:80 on each VM
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
         VM responds                    VM doesn't respond
              │                               │
     Status: Healthy ✅                Status: Unhealthy ❌
     Traffic continues                  Traffic removed
                                        automatically
```

### Health Probe Settings

```
Protocol  : TCP
Port      : 80
Interval  : 5 seconds
Threshold : 2 consecutive failures → marked unhealthy
```

### Load Balancing Rule

```
Name          : web-http-rule
Frontend IP   : web-elb-ip
Backend Pool  : web-backend-pool
Protocol      : TCP
Port          : 80
Backend Port  : 80
Session Persistence : None  (true round-robin)
```

---

## 🧪 Testing & Validation

### Test 1 — Browser Access via Load Balancer

```
http://<LoadBalancer-Frontend-IP>
```
✅ Custom NGINX page loaded successfully

### Test 2 — Curl Check

```bash
curl -I http://<LoadBalancer-Frontend-IP>
```

```
HTTP/1.1 200 OK     ✅
Server: nginx
Content-Type: text/html
```

### Test 3 — Health Probe Validation (Stop/Start Test)

```bash
# SSH into VM
ssh azureuser@<vm-public-ip>

# Stop NGINX
sudo systemctl stop nginx
```

→ Load Balancer detected failure within 10 seconds (2 × 5s interval)  
→ Browser: `http://<LB-IP>` returned connection error ✅

```bash
# Restart NGINX
sudo systemctl start nginx
```

→ Load Balancer auto-resumed traffic within 15 seconds ✅  
→ No manual intervention needed — **self-healing architecture** confirmed

---

## 💡 Key Learnings

1. **VNet is the foundation** — Without a Virtual Network, no Azure resource can communicate privately. It must be the first thing you design.

2. **Subnets enforce security boundaries** — Resources in different subnets cannot freely communicate. Traffic rules must be explicitly defined, which is what makes three-tier architecture secure by design.

3. **Health Probes make architecture self-healing** — The Load Balancer doesn't just distribute traffic; it actively monitors VM health and removes unhealthy instances automatically. Zero human intervention required.

4. **Azure Bastion eliminates attack surface** — Instead of exposing port 22 to the internet, Bastion provides browser-based SSH through Azure Portal. This is the production-grade approach.

5. **Resource Groups enable clean infrastructure lifecycle** — Grouping all resources together from day one means a single delete action removes everything cleanly with no orphaned resources left billing you.

---

## 🧹 Cleanup

To avoid Azure charges after completing the assignment:

```
Azure Portal → Resource Groups → vnet-demo-rg
→ Delete resource group
→ Type: vnet-demo-rg → Confirm
```

All resources deleted in one action:
- ✅ Virtual Network + Subnets
- ✅ Virtual Machine + NIC + Disks
- ✅ Public IP Addresses
- ✅ Load Balancer
- ✅ Bastion Host
- ✅ Network Security Groups

---



*Built with 💙 on Microsoft Azure | DevOps Micro Internship — Week 8*
