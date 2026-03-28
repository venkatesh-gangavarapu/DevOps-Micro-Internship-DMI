# Deploying a 3-Tier Book Review App on Azure using Terraform — A Complete Pin-to-Pin Guide

**Author:** Venkatesh Gangavarapu
**Stack:** Terraform · Azure · Node.js · Next.js · MySQL · Nginx · PM2

---

## Table of Contents

1. [What We Are Building](#1-what-we-are-building)
2. [The 3-Tier Architecture — Explained](#2-the-3-tier-architecture--explained)
3. [Project Structure Overview](#3-project-structure-overview)
4. [Prerequisites](#4-prerequisites)
5. [Terraform Modules — Deep Dive](#5-terraform-modules--deep-dive)
   - 5.1 [Networking Module](#51-networking-module)
   - 5.2 [Security Module](#52-security-module)
   - 5.3 [Compute Module](#53-compute-module)
   - 5.4 [Load Balancer Module](#54-load-balancer-module)
   - 5.5 [Database Module](#55-database-module)
6. [Root Configuration — How Modules Connect](#6-root-configuration--how-modules-connect)
7. [Provisioning Scripts — How the App Gets Installed](#7-provisioning-scripts--how-the-app-gets-installed)
   - 7.1 [Frontend (Web Server)](#71-frontend-web-server)
   - 7.2 [Backend (App Server)](#72-backend-app-server)
8. [Network Traffic Flow — Request to Response](#8-network-traffic-flow--request-to-response)
9. [Security Design — Why Each Rule Exists](#9-security-design--why-each-rule-exists)
10. [Step-by-Step Deployment Guide](#10-step-by-step-deployment-guide)
11. [Verifying Your Deployment](#11-verifying-your-deployment)
12. [Common Pitfalls & How to Avoid Them](#12-common-pitfalls--how-to-avoid-them)
13. [Terraform Best Practices Demonstrated](#13-terraform-best-practices-demonstrated)
14. [Azure vs AWS — Key Differences You Must Know](#14-azure-vs-aws--key-differences-you-must-know)
15. [Cleaning Up](#15-cleaning-up)
16. [Final Architecture Summary](#16-final-architecture-summary)

---

## 1. What We Are Building

We are deploying a **Book Review web application** on Microsoft Azure — completely automated using Terraform (Infrastructure as Code). No clicking in the Azure portal. No manual server setup. Everything is code, everything is repeatable.

The application has three distinct layers:

| Layer | Technology | Where |
|---|---|---|
| Frontend | Next.js (React) served via Nginx | Public VM (Web Server) |
| Backend | Node.js REST API | Private VM (App Server) |
| Database | Azure MySQL Flexible Server | Managed, VNet-integrated |

By the end of this guide, you will understand:
- How to design and deploy a production-style 3-tier architecture on Azure using Terraform
- How to structure Terraform code with reusable modules
- How network isolation (VNet, subnets, NSGs) works on Azure
- How VMs get their application code via user_data scripts at boot
- How Azure Load Balancers replace AWS ALBs
- How managed MySQL with VNet integration works
- How NAT Gateways give private subnets outbound internet without exposing inbound

---

## 2. The 3-Tier Architecture — Explained

Before touching a single line of Terraform, understand the architecture deeply. This is the mental model everything else builds on.

```
                         INTERNET
                            |
                       Port 80 (HTTP)
                            |
                  +--------------------+
                  |  Public Load       |
                  |  Balancer          |
                  |  (Standard LB)     |
                  +--------------------+
                            |
            +---------------------------------+
            |     WEB SUBNET (10.0.1.0/24)   |
            |   +-------------------------+   |
            |   |  Web Server VM          |   |
            |   |  Ubuntu 24.04 LTS       |   |
            |   |  Nginx  (port 80)       |   |
            |   |    ├── Next.js (3000)   |   |
            |   |    └── /api/* → Prv LB  |   |
            |   +-------------------------+   |
            +---------------------------------+
                            |
                       Port 3001 (API)
                            |
                  +--------------------+
                  |  Internal Load     |
                  |  Balancer          |
                  |  (10.0.10.10)      |
                  +--------------------+
                            |
            +---------------------------------+
            |    APP SUBNET (10.0.10.0/24)   |
            |   +-------------------------+   |
            |   |  App Server VM          |   |
            |   |  Ubuntu 24.04 LTS       |   |
            |   |  Node.js Backend (3001) |   |
            |   +-------------------------+   |
            |          ↑ NAT Gateway          |
            |     (outbound internet only)    |
            +---------------------------------+
                            |
                      Port 3306 (MySQL)
                            |
            +---------------------------------+
            |     DB SUBNET (10.0.20.0/24)   |
            |    (Delegated to MySQL)         |
            |   +-------------------------+   |
            |   |  Azure MySQL Flexible   |   |
            |   |  Server 8.0.21          |   |
            |   |  No public endpoint     |   |
            |   +-------------------------+   |
            +---------------------------------+
```

**Why 3 Tiers?**
- **Security:** Each tier only talks to its direct neighbor. The internet cannot reach the database, ever.
- **Scalability:** You can scale each tier independently.
- **Separation of concerns:** Frontend, business logic, and data are decoupled.

---

## 3. Project Structure Overview

```
Week-10-BookReview-Terraform-Azure/
│
├── main.tf                    # Root: wires all modules together
├── variables.tf               # Root: input variable definitions
├── outputs.tf                 # Root: final outputs (IPs, endpoints)
├── terraform.tfvars           # Your actual values (git-ignored, NEVER commit this)
├── .terraform.lock.hcl        # Provider version lock (commit this)
│
├── scripts/
│   ├── frontend-userdata.sh   # What runs on web VM at first boot
│   └── backend-userdata.sh    # What runs on app VM at first boot
│
├── modules/
│   ├── networking/            # VNet, subnets, NAT Gateway, DNS, pre-allocated IPs
│   ├── security/              # Network Security Groups (NSGs) per tier
│   ├── compute/               # Linux VMs (web & app servers)
│   ├── loadbalancer/          # Public LB + Internal LB
│   └── database/              # MySQL Flexible Server
│
├── assets/
│   └── architetural-diagram.jpeg
├── README.md
└── deployment.md
```

**Key Design Principle:** Each module is self-contained. It receives inputs via `variables.tf`, creates resources in `main.tf`, and exposes outputs via `outputs.tf`. The root `main.tf` connects them.

---

## 4. Prerequisites

Before you run `terraform apply`, make sure you have:

**Tools:**
```bash
# Install Terraform (1.0+)
# https://developer.hashicorp.com/terraform/install

# Install Azure CLI
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

# Verify installations
terraform version
az version
```

**Azure Authentication:**
```bash
# Login to Azure
az login

# List your subscriptions
az account list --output table

# Set the subscription you want to deploy into
az account set --subscription "<your-subscription-id>"
```

**Generate an SSH Key Pair:**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/book-review-key

# View the public key — you will put this in terraform.tfvars
cat ~/.ssh/book-review-key.pub
```

**Create `terraform.tfvars`** (this file is git-ignored — keep secrets here):
```hcl
project            = "book-review"
azure_location     = "centralindia"
vpc_cidr_block     = "10.0.0.0/16"

web_subnet_1_cidr  = "10.0.1.0/24"
web_subnet_2_cidr  = "10.0.2.0/24"
app_subnet_1_cidr  = "10.0.10.0/24"
app_subnet_2_cidr  = "10.0.11.0/24"
db_subnet_1_cidr   = "10.0.20.0/24"
db_subnet_2_cidr   = "10.0.21.0/24"

admin_username     = "ubuntu"
ssh_public_key     = "ssh-rsa AAAA...your-public-key-here"

db_name            = "bookreview"
db_admin_username  = "dbadmin"      # IMPORTANT: cannot be admin, root, or administrator
db_admin_password  = "YourStr0ngP@ssword!"

web_vm_size        = "Standard_B2s"
app_vm_size        = "Standard_B2s"
db_sku_name        = "B_Standard_B1ms"
db_storage_size_gb = 20
mysql_version      = "8.0.21"
```

---

## 5. Terraform Modules — Deep Dive

Modules are the building blocks. Let us go through each one, understand what resources it creates and why.

---

### 5.1 Networking Module

**Location:** `modules/networking/`
**Purpose:** Lays the entire network foundation. Everything else plugs into this.

**Resources Created:**

**Resource Group**
```hcl
resource "azurerm_resource_group" "main" {
  name     = "${var.project}-rg"
  location = var.azure_location
}
```
Think of a Resource Group as a folder in Azure. Every resource must belong to one. When you delete the resource group, everything inside it is deleted — very useful for cleanup.

**Virtual Network (VNet)**
```hcl
resource "azurerm_virtual_network" "main" {
  name                = "${var.project}-vnet"
  address_space       = [var.vpc_cidr_block]   # e.g., 10.0.0.0/16
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.main.name
}
```
Azure VNet = AWS VPC. This is your private network in the cloud. The `/16` gives you 65,536 IPs to work with.

**Subnets (6 total)**
```
Web Subnet 1:  10.0.1.0/24   (254 usable IPs) — Public
Web Subnet 2:  10.0.2.0/24   (254 usable IPs) — Public (for future multi-AZ)
App Subnet 1:  10.0.10.0/24  (254 usable IPs) — Private
App Subnet 2:  10.0.11.0/24  (254 usable IPs) — Private
DB Subnet 1:   10.0.20.0/24  (254 usable IPs) — Delegated (MySQL)
DB Subnet 2:   10.0.21.0/24  (254 usable IPs) — Delegated
```

The DB subnets have a special property called **delegation**:
```hcl
delegation {
  name = "mysql-delegation"
  service_delegation {
    name = "Microsoft.DBforMySQL/flexibleServers"
    actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}
```
This tells Azure: "This subnet is exclusively for MySQL Flexible Server." Azure needs this to inject the managed MySQL service directly into your VNet.

**NAT Gateway**
```hcl
resource "azurerm_nat_gateway" "main" {
  name                = "${var.project}-nat-gw"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
}
```
App server VMs are in a private subnet with no public IP. But they still need outbound internet to install packages (npm install, apt install). The NAT Gateway provides this — outbound only. No inbound traffic reaches the private subnet from the internet.

NAT Gateway associations:
- Linked to a Public IP (for the outbound source address)
- Associated with App Subnet 1 and App Subnet 2

**Pre-Allocated Public IPs (Critical Design Decision)**
```hcl
# Public IP for the Public Load Balancer
resource "azurerm_public_ip" "public_lb" {
  name                = "${var.project}-public-lb-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_location
  allocation_method   = "Static"
  sku                 = "Standard"
}
```

Why is this IP allocated in the **networking** module instead of the **loadbalancer** module?

**This solves a circular dependency:**
- The `compute` module needs the public LB IP to inject into the frontend user_data script (Nginx config and Next.js `.env`)
- The `loadbalancer` module needs the VM's NIC ID to register it in the backend pool
- If both the IP and the LB were in the loadbalancer module, compute would depend on loadbalancer and loadbalancer would depend on compute — a deadlock

By pre-allocating the IP in the networking module (which neither depends on compute nor loadbalancer), both modules can use it independently.

**Private DNS Zone for MySQL**
```hcl
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${var.project}-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}
```
The MySQL server's hostname (`book-review-mysql-server.mysql.database.azure.com`) needs to resolve within your VNet. This private DNS zone handles that. Without it, VMs cannot connect to MySQL by hostname — only by private IP, which can change.

**Static Private IP for Internal Load Balancer**
```hcl
output "private_lb_ip" {
  value = cidrhost(var.app_subnet_1_cidr, 10)  # 10.0.10.10
}
```
The internal LB needs a stable private IP so Nginx can forward `/api/*` requests to it. `cidrhost(subnet, 10)` computes the 10th host in the subnet — deterministic and clean.

---

### 5.2 Security Module

**Location:** `modules/security/`
**Purpose:** Network Security Groups (NSGs) enforce the 3-tier isolation.

**How Azure NSGs Work:**
- NSGs are attached to **subnets** (not individual VMs like AWS Security Groups)
- Rules have a **priority** (lower number = higher priority, 100–4096)
- Rules are evaluated in priority order; first match wins
- Azure has built-in default rules (AllowVnetInBound, AllowAzureLoadBalancerInBound, DenyAllInbound) at priority 65000+
- Your custom rules override defaults

**Web NSG (Public-Facing)**
```hcl
# Allow HTTP from internet
security_rule {
  name                       = "allow-http"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "Internet"
  destination_port_range     = "80"
}

# Allow SSH from internet (restrict to your IP in production)
security_rule {
  name                       = "allow-ssh"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "Internet"
  destination_port_range     = "22"
}

# Azure Load Balancer health probes must be allowed
security_rule {
  name                       = "allow-lb-health"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "AzureLoadBalancer"
  destination_port_range     = "*"
}
```

**App NSG (Private, Locked Down)**
```hcl
# Only web subnets can reach the backend API
security_rule {
  name                       = "allow-backend-from-web1"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "10.0.1.0/24"  # Web Subnet 1
  destination_port_range     = "3001"
}

# SSH only from web subnets (web server acts as bastion)
security_rule {
  name                       = "allow-ssh-from-web"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "10.0.1.0/24"
  destination_port_range     = "22"
}

# Explicitly deny everything else
security_rule {
  name                       = "deny-all-inbound"
  priority                   = 4096
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_address_prefix      = "*"
  destination_port_range     = "*"
}
```

The explicit deny rule is important. By default, Azure's `AllowVnetInBound` rule (priority 65000) would allow ALL traffic within the VNet. The explicit deny at priority 4096 overrides this for our app subnet, ensuring only the traffic we explicitly allow gets through.

**DB NSG (Most Restrictive)**
```hcl
# Only app subnets can query MySQL
security_rule {
  name                       = "allow-mysql-from-app1"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "10.0.10.0/24"  # App Subnet 1
  destination_port_range     = "3306"
}

# Block everything else
security_rule {
  name                       = "deny-all-inbound"
  priority                   = 4096
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_address_prefix      = "*"
  destination_port_range     = "*"
}
```

---

### 5.3 Compute Module

**Location:** `modules/compute/`
**Purpose:** Creates the two Linux VMs.

**Network Interfaces (NICs)**

Before creating a VM, you must create its network interface and attach it to a subnet:

```hcl
# Web Server NIC — in public subnet
resource "azurerm_network_interface" "web" {
  name                = "${var.project}-web-nic"
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "web-ip-config"
    subnet_id                     = var.web_subnet_id       # 10.0.1.0/24
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.web_public_ip_id    # Has a public IP
  }
}

# App Server NIC — in private subnet
resource "azurerm_network_interface" "app" {
  name                = "${var.project}-app-nic"
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "app-ip-config"
    subnet_id                     = var.app_subnet_id       # 10.0.10.0/24
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id — this VM has NO public IP
  }
}
```

**Web Server VM**
```hcl
resource "azurerm_linux_virtual_machine" "web" {
  name                = "${var.project}-web-server"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  size                = var.web_vm_size            # Standard_B2s
  admin_username      = var.admin_username         # ubuntu

  network_interface_ids = [azurerm_network_interface.web.id]

  # SSH authentication via public key
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key   # Full key content, e.g., "ssh-rsa AAAA..."
  }

  # Provisioning script runs at first boot
  custom_data = base64encode(var.web_user_data)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
```

**Key Azure vs AWS differences here:**
- `custom_data` = user_data in AWS. Azure requires it base64-encoded (`base64encode()`).
- `admin_ssh_key.public_key` takes the **full key content** (`ssh-rsa AAAA...`), not a key pair name like AWS.
- OS disk must be explicitly defined (AWS has sensible implicit defaults).
- `source_image_reference` uses publisher/offer/sku/version instead of an AMI ID.

**App Server VM** — identical structure but:
- Uses `app_vm_size` and `app_subnet_id`
- No `public_ip_address_id` on the NIC
- Gets a different user_data script (`backend-userdata.sh`)

---

### 5.4 Load Balancer Module

**Location:** `modules/loadbalancer/`
**Purpose:** Two load balancers — one public (internet-facing), one internal (web-to-app).

**Public Load Balancer**
```hcl
resource "azurerm_lb" "public" {
  name                = "${var.project}-public-lb"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = var.public_lb_ip_id   # Pre-allocated in networking module
  }
}

# Backend pool — web VMs register here
resource "azurerm_lb_backend_address_pool" "public" {
  loadbalancer_id = azurerm_lb.public.id
  name            = "public-backend-pool"
}

# Register web server NIC into the backend pool
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  network_interface_id    = var.web_nic_id
  ip_configuration_name   = "web-ip-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.public.id
}

# Health probe — checks if the web VM is alive on port 80
resource "azurerm_lb_probe" "public" {
  loadbalancer_id = azurerm_lb.public.id
  name            = "http-probe"
  port            = 80
  protocol        = "Tcp"
  interval_in_seconds  = 30
  number_of_probes     = 2
}

# Load balancing rule — route port 80 traffic to backend pool
resource "azurerm_lb_rule" "public" {
  loadbalancer_id                = azurerm_lb.public.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.public.id]
  probe_id                       = azurerm_lb_probe.public.id
  disable_outbound_snat          = true   # Web VM has its own public IP for outbound
}
```

**Internal Load Balancer**
```hcl
resource "azurerm_lb" "internal" {
  name                = "${var.project}-internal-lb"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "internal-frontend"
    subnet_id                     = var.app_subnet_id
    private_ip_address            = var.private_lb_ip      # 10.0.10.10 — static, predictable
    private_ip_address_allocation = "Static"
  }
}
```

The internal LB has a **static private IP (10.0.10.10)**. This IP is baked into the Nginx config on the web server. When Nginx sees a request to `/api/*`, it forwards to `http://10.0.10.10:3001`. The internal LB then routes that to the app server VM.

Why use an internal LB instead of direct VM-to-VM communication?
- The IP `10.0.10.10` is stable — even if the app VM is destroyed and recreated, the IP stays the same
- In a scaled-out setup, the internal LB distributes requests across multiple app VMs

---

### 5.5 Database Module

**Location:** `modules/database/`
**Purpose:** Managed MySQL Flexible Server, VNet-integrated.

```hcl
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "${var.project}-mysql-server"
  resource_group_name    = var.resource_group_name
  location               = var.azure_location
  administrator_login    = var.db_admin_username    # "dbadmin" — Azure reserves admin/root/administrator
  administrator_password = var.db_admin_password
  backup_retention_days  = 7
  delegated_subnet_id    = var.db_subnet_id         # Must be the delegated subnet
  private_dns_zone_id    = var.private_dns_zone_id  # For hostname resolution inside VNet
  sku_name               = var.db_sku_name          # "B_Standard_B1ms"
  version                = var.mysql_version        # "8.0.21"
  zone                   = "1"

  storage {
    size_gb         = var.db_storage_size_gb        # 20 GB
    auto_grow_enabled = true
  }

  high_availability {
    mode = "Disabled"   # Single-zone for dev/test (saves cost)
  }
}

resource "azurerm_mysql_flexible_database" "main" {
  name                = var.db_name                 # "bookreview"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
```

**What "VNet-integrated" means:** The MySQL server is injected directly into your VNet via the delegated subnet. It gets a private IP in that subnet. There is no public endpoint — the server is invisible to the internet. Only VMs inside your VNet (specifically those in the app subnet, per the NSG) can connect to it.

The output `db_host` returns the server's FQDN:
```
book-review-mysql-server.mysql.database.azure.com
```
This resolves to the private IP of the MySQL server — only within your VNet, thanks to the private DNS zone.

---

## 6. Root Configuration — How Modules Connect

The root `main.tf` is the conductor. It calls each module and wires their outputs into the next module's inputs.

```hcl
provider "azurerm" {
  features {}
}

# Step 1: Foundation — VNet, subnets, NAT, DNS, pre-allocated IPs
module "networking" {
  source             = "./modules/networking"
  project            = var.project
  azure_location     = var.azure_location
  vpc_cidr_block     = var.vpc_cidr_block
  web_subnet_1_cidr  = var.web_subnet_1_cidr
  # ... all subnet CIDRs
}

# Step 2: Security — NSGs use subnet IDs from networking
module "security" {
  source              = "./modules/security"
  project             = var.project
  resource_group_name = module.networking.resource_group_name
  web_subnet_1_id     = module.networking.web_subnet_1_id
  app_subnet_1_id     = module.networking.app_subnet_1_id
  # ...
}

# Step 3: Database — needs delegated subnet and DNS zone
module "database" {
  source              = "./modules/database"
  project             = var.project
  resource_group_name = module.networking.resource_group_name
  db_subnet_id        = module.networking.db_subnet_1_id
  private_dns_zone_id = module.networking.private_dns_zone_id
  db_admin_username   = var.db_admin_username
  db_admin_password   = var.db_admin_password
  db_name             = var.db_name
}

# Step 4: Compute — uses templatefile() to inject dynamic values into boot scripts
module "compute" {
  source              = "./modules/compute"
  project             = var.project
  resource_group_name = module.networking.resource_group_name
  web_subnet_id       = module.networking.web_subnet_1_id
  app_subnet_id       = module.networking.app_subnet_1_id
  web_public_ip_id    = module.networking.web_public_ip_id
  ssh_public_key      = var.ssh_public_key

  # templatefile() reads the shell script and substitutes ${variable} placeholders
  web_user_data = templatefile("${path.root}/scripts/frontend-userdata.sh", {
    public_lb_ip  = module.networking.public_lb_ip    # Injected into Nginx config & Next.js .env
    private_lb_ip = module.networking.private_lb_ip   # Injected into Nginx upstream config
  })

  app_user_data = templatefile("${path.root}/scripts/backend-userdata.sh", {
    db_host      = module.database.db_host            # MySQL FQDN
    db_user      = var.db_admin_username
    db_pass      = var.db_admin_password
    db_name      = var.db_name
    public_lb_ip = module.networking.public_lb_ip     # Injected into CORS allowed origins
  })
}

# Step 5: Load Balancer — needs NIC IDs from compute and IPs from networking
module "loadbalancer" {
  source              = "./modules/loadbalancer"
  project             = var.project
  resource_group_name = module.networking.resource_group_name
  public_lb_ip_id     = module.networking.public_lb_ip_id   # Pre-allocated in networking
  web_nic_id          = module.compute.web_nic_id
  app_nic_id          = module.compute.app_nic_id
  app_subnet_id       = module.networking.app_subnet_1_id
  private_lb_ip       = module.networking.private_lb_ip     # 10.0.10.10
}
```

**`templatefile()` is the secret sauce.** It reads a shell script file and replaces `${variable}` placeholders with actual values at plan time — before Terraform sends the script to the VM. This means your user_data scripts are dynamic and configuration-free. No hardcoded IPs anywhere.

---

## 7. Provisioning Scripts — How the App Gets Installed

These are bash scripts that run **once, at first boot** of each VM. Azure calls this `custom_data`. Think of it as the VM's birth certificate — it defines what the VM becomes.

---

### 7.1 Frontend (Web Server)

**File:** `scripts/frontend-userdata.sh`

Step by step what this script does:

```bash
#!/bin/bash
exec > /var/log/frontend-user-data.log 2>&1   # Log everything for debugging

# 1. System updates
apt update -y && apt upgrade -y

# 2. Install Node.js LTS via NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# 3. Install Nginx and Git
apt install -y nginx git

# 4. Clone the application repository
git clone https://github.com/pravinmishraaws/book-review-app.git /home/ubuntu/book-review-app
cd /home/ubuntu/book-review-app/frontend

# 5. Install JavaScript dependencies
npm install

# 6. Create environment file for Next.js
# ${public_lb_ip} was injected by templatefile() at Terraform plan time
cat > .env.local << EOF
NEXT_PUBLIC_API_URL=http://${public_lb_ip}
EOF

# 7. Build the production Next.js bundle
npm run build

# 8. Install PM2 — Node.js process manager (keeps the app running)
npm install -g pm2

# 9. Start Next.js with PM2 on port 3000 (local only, not exposed externally)
pm2 start npm --name frontend -- start
pm2 startup systemd -u ubuntu
pm2 save

# 10. Configure Nginx as reverse proxy
cat > /etc/nginx/sites-available/book-review << EOF
server {
    listen 80;
    server_name _;

    # /api/* requests → forwarded to internal load balancer → app server
    location /api/ {
        proxy_pass http://${private_lb_ip}:3001/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # All other requests → Next.js running locally on port 3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# 11. Enable and start Nginx
ln -sf /etc/nginx/sites-available/book-review /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
```

**What ports are in use on the web server:**
- Port 80: Nginx (open to internet via NSG and LB)
- Port 3000: Next.js (local only, Nginx proxies to it)
- Port 22: SSH (open to internet via NSG, for admin access)

---

### 7.2 Backend (App Server)

**File:** `scripts/backend-userdata.sh`

```bash
#!/bin/bash
exec > /var/log/backend-user-data.log 2>&1

# 1. System updates
apt update -y && apt upgrade -y

# 2. Install Node.js LTS, mysql-client, git
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs mysql-client git

# 3. Clone the application repository
git clone https://github.com/pravinmishraaws/book-review-app.git /home/ubuntu/book-review-app
cd /home/ubuntu/book-review-app/backend

# 4. Install backend dependencies
npm install

# 5. Create .env file with database credentials
# All ${variables} injected by templatefile() at Terraform plan time
cat > .env << EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
DB_DIALECT=mysql
PORT=3001
JWT_SECRET=mysecret
ALLOWED_ORIGINS=http://${public_lb_ip}
EOF

# 6. Install PM2 and start backend
npm install -g pm2
pm2 start src/server.js --name bk-backend
pm2 startup systemd -u ubuntu
pm2 save
```

**What ports are in use on the app server:**
- Port 3001: Node.js backend (accessible only from web subnets via NSG)
- Port 22: SSH (accessible only from web subnets — use web VM as jump host)
- Outbound: NAT Gateway provides internet access for package installs

**The `.env` file values at runtime look like:**
```
DB_HOST=book-review-mysql-server.mysql.database.azure.com
DB_USER=dbadmin
DB_PASS=YourStr0ngP@ssword!
DB_NAME=bookreview
DB_DIALECT=mysql
PORT=3001
JWT_SECRET=mysecret
ALLOWED_ORIGINS=http://40.x.x.x
```

---

## 8. Network Traffic Flow — Request to Response

Let us trace a complete request from a user's browser to the database and back.

**Scenario: User visits the Book Review app and views a list of books**

```
1. USER BROWSER
   GET http://40.x.x.x/books
   ↓
2. PUBLIC LOAD BALANCER (40.x.x.x, port 80)
   - Checks health probe on web VM (TCP port 80)
   - Routes request to web server NIC
   ↓
3. NGINX on WEB SERVER VM
   - Receives request on port 80
   - URL is /books → does NOT match /api/*
   - Proxies to http://localhost:3000/books
   ↓
4. NEXT.JS (localhost:3000)
   - Server-side renders the /books page
   - During rendering, makes an API call to NEXT_PUBLIC_API_URL/api/books
   - NEXT_PUBLIC_API_URL = http://40.x.x.x (public LB IP)
   ↓
5. API REQUEST: GET http://40.x.x.x/api/books
   - Goes back to Nginx
   - URL matches /api/* → proxy_pass to http://10.0.10.10:3001/api/books
   ↓
6. INTERNAL LOAD BALANCER (10.0.10.10:3001)
   - Routes request to app server NIC in app subnet
   ↓
7. NODE.JS BACKEND on APP SERVER VM (port 3001)
   - Processes GET /api/books
   - Queries MySQL: SELECT * FROM books
   ↓
8. MYSQL FLEXIBLE SERVER (private DNS: book-review-mysql-server.mysql.database.azure.com)
   - Resolves via Private DNS Zone to private IP in DB subnet
   - Returns books data to Node.js
   ↓
9. Response flows back: MySQL → Node.js → Internal LB → Nginx → Next.js → Browser
```

---

## 9. Security Design — Why Each Rule Exists

Every NSG rule has a reason. Understanding these prevents misconfigurations in production.

| Rule | NSG | Allows | Reason |
|---|---|---|---|
| Allow HTTP port 80 from Internet | Web NSG | Users reach the app | Core application access |
| Allow SSH port 22 from Internet | Web NSG | Admin access to web VM | Management (restrict to your IP in production) |
| Allow AzureLoadBalancer | Web NSG | LB health probes | Without this, LB marks VM as down even if it is healthy |
| Allow port 3001 from 10.0.1.0/24 | App NSG | Web server calls backend | Only web tier should use the API |
| Allow SSH from 10.0.1.0/24 | App NSG | Jump via web VM to app VM | No direct SSH to app server from internet |
| Explicit DENY all inbound | App NSG | Nothing else | Overrides Azure default AllowVnetInBound — critical |
| Allow MySQL 3306 from 10.0.10.0/24 | DB NSG | App server queries DB | Only app tier accesses data |
| Explicit DENY all inbound | DB NSG | Nothing else | DB is completely isolated |

**Why the explicit DENY matters:** Azure's default network rules include `AllowVnetInBound` at priority 65000, which allows ALL traffic between resources in the same VNet. Without explicit deny rules, any VM in your VNet could connect to any other — the "3-tier isolation" would be an illusion.

---

## 10. Step-by-Step Deployment Guide

```bash
# Step 1: Clone or navigate to the project
cd Week-10-BookReview-Terraform-Azure

# Step 2: Create your tfvars file (see Prerequisites section)
# terraform.tfvars is git-ignored — create it fresh

# Step 3: Initialize Terraform (download provider, set up backend)
terraform init

# Expected output:
# Initializing the backend...
# Initializing provider plugins...
# - Finding hashicorp/azurerm versions matching "~> 3.0"...
# - Installed hashicorp/azurerm v3.117.1
# Terraform has been successfully initialized!

# Step 4: Validate syntax and configuration
terraform validate

# Expected output: Success! The configuration is valid.

# Step 5: Preview what will be created (read this carefully)
terraform plan

# You will see ~35+ resources planned across all modules
# Look for any unexpected changes before proceeding

# Step 6: Deploy
terraform apply

# Type "yes" when prompted
# Deployment takes approximately 5–10 minutes
# MySQL provisioning is usually the slowest step

# Step 7: Get the outputs
terraform output

# You will see:
# public_lb_ip     = "40.x.x.x"       ← Application entry point
# webserver_pub_ip = "20.x.x.x"       ← SSH access to web VM
# appserver_prvt_ip = "10.0.10.x"     ← Private IP (SSH via web VM as jump host)
# db_endpoint      = "book-review-mysql-server.mysql.database.azure.com"
# private_lb_ip    = "10.0.10.10"

# Step 8: Wait 5–10 minutes for user_data scripts to finish running
# Then open your browser:
# http://<public_lb_ip>
```

---

## 11. Verifying Your Deployment

**Check the application:**
```bash
# Should return 200 OK
curl -I http://<public_lb_ip>

# Test the API endpoint
curl http://<public_lb_ip>/api/books
```

**SSH into the web server:**
```bash
ssh -i ~/.ssh/book-review-key ubuntu@<webserver_pub_ip>

# Check frontend logs
sudo cat /var/log/frontend-user-data.log

# Check PM2 processes
pm2 status
# Should show: frontend   online

# Check Nginx status
sudo systemctl status nginx
sudo nginx -t
```

**SSH into the app server (via web server as jump host):**
```bash
ssh -i ~/.ssh/book-review-key \
    -J ubuntu@<webserver_pub_ip> \
    ubuntu@<appserver_prvt_ip>

# Check backend logs
sudo cat /var/log/backend-user-data.log

# Check PM2 processes
pm2 status
# Should show: bk-backend   online

# Check the .env file was created correctly
cat /home/ubuntu/book-review-app/backend/.env

# Test database connectivity from app server
mysql -h book-review-mysql-server.mysql.database.azure.com \
      -u dbadmin -p bookreview
```

**Check Nginx config on web server:**
```bash
cat /etc/nginx/sites-available/book-review
# Verify private_lb_ip (10.0.10.10) is in the /api/ proxy_pass
# Verify localhost:3000 is in the / proxy_pass
```

---

## 12. Common Pitfalls & How to Avoid Them

**1. Reserved database username**
```
Error: creating MySQL Flexible Server: Code="InvalidParameterValue"
Message="'admin' is reserved"
```
Solution: Use `dbadmin`, `mysqluser`, or anything that is not `admin`, `root`, `administrator`, `azure_superuser`.

**2. SSH public key format**
```
Error: admin_ssh_key.public_key must begin with 'ssh-rsa', 'ecdsa', 'ssh-ed25519'
```
Solution: The value in `terraform.tfvars` must be the full public key content starting with `ssh-rsa AAAA...`. Not the file path. Run `cat ~/.ssh/book-review-key.pub` and paste the output.

**3. custom_data does not re-run on `terraform apply` if VM already exists**
Terraform only runs `custom_data` at VM creation. If you change the user_data script and run `terraform apply` on an existing VM, nothing happens. To re-run scripts, you must destroy and recreate the VM (`terraform taint azurerm_linux_virtual_machine.web` then `terraform apply`).

**4. MySQL delegation conflict**
```
Error: subnet must be delegated to Microsoft.DBforMySQL/flexibleServers
```
Solution: Ensure the DB subnet has the delegation block in the networking module. A subnet can only be delegated to one service type.

**5. Load balancer SNAT exhaustion**
If outbound connectivity from the web VM fails mysteriously, it may be SNAT exhaustion. The web VM has a public IP and `disable_outbound_snat = true` on the LB rule — so it uses its own public IP for outbound. This is the correct design; do not set `disable_outbound_snat = false`.

**6. App server cannot install packages**
If the backend user_data script fails at `apt install` or `npm install`, the NAT Gateway or its public IP may not be properly associated with the app subnet. Check the NAT Gateway subnet association in the networking module.

**7. Circular dependency if you move the public LB IP to the loadbalancer module**
As explained in section 5.1, the public LB IP must be in the networking module. If you move it to the loadbalancer module, you get:
```
Error: Cycle: module.compute → module.loadbalancer → module.compute
```

---

## 13. Terraform Best Practices Demonstrated

This project is a good reference for several Terraform best practices:

**1. Modular Design**
Resources are grouped by function (networking, security, compute, etc.), not by resource type. This makes the code easier to navigate, test, and reuse in other projects.

**2. No Hardcoded Values**
Every configurable value is a variable. Infrastructure for a different project can be deployed by changing only `terraform.tfvars`.

**3. templatefile() for Dynamic Scripts**
User_data scripts are not hardcoded with IPs or credentials. `templatefile()` injects runtime values at plan time.

**4. Explicit Dependency Management**
Module dependencies are explicit via output-to-input wiring. Terraform builds the correct dependency graph automatically.

**5. Sensitive Variables**
Database password and SSH key are marked `sensitive = true` in `variables.tf`, preventing them from appearing in plain text in Terraform output.

**6. `.gitignore` for Secrets**
`terraform.tfvars` (contains DB password, SSH key), `terraform.tfstate` (contains all resource details including secrets), and `.terraform/` (provider binaries) are all git-ignored.

**7. `.terraform.lock.hcl` Committed**
The lock file pins provider versions. This ensures every team member and CI pipeline uses the exact same provider version — no "works on my machine" surprises.

**8. Outputs for Downstream Consumption**
Every module exposes its outputs. The root module aggregates the outputs you need post-deployment (public IP, private IP, DB endpoint).

---

## 14. Azure vs AWS — Key Differences You Must Know

If you are coming from AWS, these are the mental model shifts:

| Concept | AWS | Azure | Notes |
|---|---|---|---|
| Virtual private network | VPC | Virtual Network (VNet) | Same concept, different name |
| Firewall rules | Security Group (per instance) | NSG (per subnet or NIC) | Azure NSGs on subnets are more like AWS NACLs |
| Load balancer | ALB / NLB | Azure Load Balancer (Standard) | Azure LB is Layer 4 only; for Layer 7 use Application Gateway |
| Managed MySQL | RDS MySQL | MySQL Flexible Server | Azure version supports VNet injection via delegation |
| Outbound internet for private subnet | NAT Gateway | NAT Gateway | Same concept, almost identical naming |
| User data / cloud-init | `user_data` | `custom_data` | Both execute at first boot; Azure requires base64 encoding |
| SSH key authentication | Key pair (named, stored in AWS) | Admin SSH key (content passed directly) | Azure does not store or name keys |
| VM image | AMI (image ID) | publisher/offer/sku/version | Azure uses a 4-part image reference |
| DNS for private services | Route 53 Private Hosted Zone | Azure Private DNS Zone | Almost identical functionality |
| Resource organization | Tags only | Resource Groups (mandatory) | Every Azure resource must belong to a Resource Group |
| Provider authentication | AWS credentials / IAM role | `az login` / Service Principal | `az login` works for local dev; use Service Principal for CI |
| Availability Zones | Explicit (us-east-1a, b, c) | Zone numbers (1, 2, 3) | Azure zones are numbered, not named |

---

## 15. Cleaning Up

When you are done experimenting, destroy all resources to avoid Azure charges:

```bash
terraform destroy

# Type "yes" when prompted
# This deletes everything in reverse dependency order:
# Load Balancer → Compute → Database → Security → Networking → Resource Group
```

**Important:** Azure charges for:
- Running VMs (even when stopped, you pay for allocated compute in some cases)
- Public IPs (Standard SKU charges even when not attached)
- MySQL Flexible Server (charged per hour)
- NAT Gateway (charged per hour)
- Load Balancers (charged per rule per hour)

`terraform destroy` removes all of these. Verify in the Azure portal that the resource group is gone.

---

## 16. Final Architecture Summary

```
+----------------------------------------------------------+
|                    AZURE REGION (Central India)          |
|                                                          |
|  +----------------------------------------------------+  |
|  |          RESOURCE GROUP: book-review-rg            |  |
|  |                                                    |  |
|  |  +----------------------------------------------+  |  |
|  |  |        VNET: 10.0.0.0/16                     |  |  |
|  |  |                                              |  |  |
|  |  |  WEB SUBNET (10.0.1.0/24)                   |  |  |
|  |  |  NSG: Allow 80, 22 from Internet            |  |  |
|  |  |  [Web Server VM] ←── Public IP (SSH)        |  |  |
|  |  |       Nginx(80) → Next.js(3000)             |  |  |
|  |  |       /api/* → Internal LB (10.0.10.10)     |  |  |
|  |  |                                              |  |  |
|  |  |  APP SUBNET (10.0.10.0/24)                  |  |  |
|  |  |  NSG: Allow 3001, 22 from Web only          |  |  |
|  |  |  [App Server VM] (No public IP)             |  |  |
|  |  |       Node.js(3001)                         |  |  |
|  |  |       Outbound: NAT Gateway                 |  |  |
|  |  |                                              |  |  |
|  |  |  DB SUBNET (10.0.20.0/24) [Delegated]       |  |  |
|  |  |  NSG: Allow 3306 from App only              |  |  |
|  |  |  [MySQL Flexible Server] (No public IP)     |  |  |
|  |  |       DNS: *.mysql.database.azure.com       |  |  |
|  |  |                                              |  |  |
|  |  +----------------------------------------------+  |  |
|  |                                                    |  |
|  |  Public LB (40.x.x.x:80) → Web VM               |  |  |
|  |  Internal LB (10.0.10.10:3001) → App VM          |  |  |
|  |  NAT Gateway → Outbound internet for app subnet  |  |  |
|  |  Private DNS Zone → MySQL FQDN resolution        |  |  |
|  +----------------------------------------------------+  |
+----------------------------------------------------------+
```

**Resources Created: ~35 total**
- 1 Resource Group
- 1 VNet, 6 Subnets
- 3 NSGs + 6 Subnet Associations
- 2 VMs, 2 NICs
- 2 Public IPs (web VM, NAT Gateway)
- 1 NAT Gateway + subnet association
- 2 Load Balancers, 2 Backend Pools, 2 Health Probes, 2 LB Rules, 2 NIC-Pool Associations
- 1 MySQL Flexible Server, 1 MySQL Database
- 1 Private DNS Zone + VNet Link

**Deployment time:** ~8–12 minutes (MySQL is the bottleneck)

---

## Key Takeaways

1. **Modular Terraform** makes infrastructure readable, reusable, and maintainable. Organize by function, not resource type.

2. **3-tier isolation** is not just about subnets — it is about NSG rules that explicitly deny lateral movement. Without the explicit DENY rules, Azure's default AllowVnetInBound makes the isolation meaningless.

3. **The circular dependency problem** (compute needs LB IP, LB needs compute NIC) is solved by pre-allocating the IP in a shared networking module. Recognizing and solving circular dependencies is a critical Terraform skill.

4. **templatefile()** is the clean way to inject runtime values (IPs, credentials) into user_data scripts. No hardcoding. No separate configuration management tool needed for simple deployments.

5. **VNet-integrated MySQL** (via subnet delegation) is the Azure-native way to make a managed database private. No public endpoint, no VPN, no peering required — it is just inside your VNet.

6. **NAT Gateway** gives private subnets controlled outbound internet access. VMs can install packages and pull code from GitHub, but nobody from the internet can initiate a connection inbound.

7. **Never commit `terraform.tfvars` or `terraform.tfstate`** — they contain your credentials, SSH keys, and the state of every deployed resource.

---

*This project is part of the DevOps Micro Internship — Week 10: Terraform and Infrastructure as Code.*
