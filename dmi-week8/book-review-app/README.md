# 📚 Book Review App — Production Three-Tier Architecture on Azure

> **Week 8 — Assignment 4 | DevOps Micro Internship by Pravin Mishra**  
> A fully production-grade, three-tier web application deployed on Microsoft Azure using real DevOps practices.

---

## 🏗️ Architecture Overview

```
          INTERNET
              |
              ▼
   ┌─────────────────────┐
   │  Public Load Balancer│  ← web-public-lb (Standard, Zone-redundant)
   └──────────┬──────────┘
              │ round-robin
       ┌──────┴──────┐
       ▼             ▼
  [web-vm-1]    [web-vm-2]       WEB TIER — Public Subnets
  Next.js        Next.js         Zone 1        Zone 2
  NGINX :80      NGINX :80
       └──────┬──────┘
              │ /api/* → 10.0.4.100:3001
              ▼
   ┌─────────────────────┐
   │ Internal Load Balancer│ ← app-internal-lb (10.0.4.100)
   └──────────┬──────────┘
              │ round-robin
       ┌──────┴──────┐
       ▼             ▼
  [app-vm-1]    [app-vm-2]       APP TIER — Private Subnets
  Node.js        Node.js         Zone 1        Zone 2
  :3001          :3001
       └──────┬──────┘
              │ Port 3306
              ▼
   ┌─────────────────────┐
   │  Azure MySQL HA      │  ← bookreview-mysql (Zone Redundant)
   │  Primary (Zone 1)    │     Auto-failover to Zone 2
   └──────────┬──────────┘
              │ async replication
              ▼
   ┌─────────────────────┐
   │   Read Replica       │  ← bookreview-mysql-replica (Zone 3)
   └─────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Web Tier | Next.js + NGINX | Frontend + Reverse Proxy |
| App Tier | Node.js / Express | REST API on port 3001 |
| Database | Azure MySQL 8.0 | Persistent data store |
| Process Manager | PM2 | Keep Node.js alive across reboots |
| Load Balancing | Azure Standard LB | Traffic distribution + health checks |
| Infrastructure | Azure VNet, NSGs, Subnets | Network isolation + security |

---

## 🌐 Network Design

### IP Plan — 6 Subnets Across 2 Zones

| Subnet | CIDR | Zone | Tier | Type |
|---|---|---|---|---|
| web-subnet-1 | 10.0.1.0/24 | Zone 1 | Web | Public |
| web-subnet-2 | 10.0.2.0/24 | Zone 2 | Web | Public |
| app-subnet-1 | 10.0.3.0/24 | Zone 1 | App | Private |
| app-subnet-2 | 10.0.4.0/24 | Zone 2 | App | Private |
| db-subnet-1 | 10.0.5.0/24 | Zone 1 | DB | Private |
| db-subnet-2 | 10.0.6.0/24 | Zone 2 | DB | Private |

### NSG Security Rules

| NSG | Port | Source | Purpose |
|---|---|---|---|
| web-nsg | 80, 443 | Any | Public web traffic |
| web-nsg | 22 | My IP only | SSH admin access |
| app-nsg | 3001 | 10.0.1.0/24 + 10.0.2.0/24 | Web → App only |
| app-nsg | 22 | 10.0.1.0/24 | Jump box SSH |
| db-nsg | 3306 | 10.0.3.0/24 + 10.0.4.0/24 | App → DB only |

> 🔐 **Security Model:** Traffic flows ONE direction: Internet → Web → App → Database. The browser never sees private IPs. NGINX is the security boundary.

---

## 🚀 Deployment — Step by Step

### Prerequisites
- Azure account (Free tier works for most resources)
- SSH client
- Basic Linux knowledge

---

### Task 1 — VNet and Subnets

```bash
# Azure Portal → Virtual Networks → + Create
# Name: bookreview-vnet | Region: Central India | CIDR: 10.0.0.0/16
# Add all 6 subnets as per IP plan above
# Create 3 NSGs (web-nsg, app-nsg, db-nsg) and associate to subnets
```

---

### Task 2 — Load Balancers

```bash
# Public LB
# Name: web-public-lb | Type: Public | SKU: Standard
# Frontend: web-lb-pip (Static public IP)
# Health Probe: HTTP:80 | Rule: Port 80 → 80

# Internal LB
# Name: app-internal-lb | Type: Internal | SKU: Standard
# Frontend: 10.0.4.100 (Static private IP on app-subnet-2)
# Health Probe: TCP:3001 | Rule: Port 3001 → 3001
```

---

### Task 3 — Virtual Machines

```bash
# Web VMs (web-vm-1, web-vm-2)
# Zone 1 + Zone 2 | web-subnet-1 + web-subnet-2 | With public IP
# Ubuntu 22.04 LTS | Standard_B1s

# Install on both web VMs:
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs nginx git
sudo npm install -g pm2
sudo systemctl enable nginx && sudo systemctl start nginx

# App VMs (app-vm-1, app-vm-2)
# Zone 1 + Zone 2 | app-subnet-1 + app-subnet-2 | NO public IP
# Access via jump box: laptop → web-vm-1 → app-vm-1

# ⚠️ App VMs need NAT Gateway for outbound internet (npm install)
# Create: app-nat-gateway → associate to app-subnet-1 + app-subnet-2

# Install on both app VMs (via jump box):
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs git mysql-client
sudo npm install -g pm2
```

---

### Task 4 — Azure MySQL

```bash
# Azure Portal → Azure Database for MySQL → Flexible Server → + Create
# Name: bookreview-mysql | Region: Central India | MySQL 8.0
# Workload: Production | HA: Zone redundant | Standby: Zone 2
# Networking: Private access | Subnet: db-subnet-1
# Private DNS: bookreview.mysql.database.azure.com

# Read Replica:
# bookreview-mysql → Replication → + Add Replica
# Name: bookreview-mysql-replica | Zone 3

# Create database (from app-vm-1 via jump box):
mysql -h bookreview-mysql.mysql.database.azure.com -u bookreviewadmin -p

CREATE DATABASE bookreview;
USE bookreview;

CREATE TABLE books (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    title     VARCHAR(255) NOT NULL,
    author    VARCHAR(255) NOT NULL,
    rating    DECIMAL(3,1),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    name      VARCHAR(255) NOT NULL,
    email     VARCHAR(255) NOT NULL UNIQUE,
    password  VARCHAR(255) NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

### Task 5 — Deploy Application

**Backend — on both app VMs:**

```bash
git clone <repo-url> ~/book-review-app
cd ~/book-review-app/backend

# Create .env
cat > .env << 'ENVEOF'
DB_HOST=bookreview-mysql.mysql.database.azure.com
DB_READ_HOST=bookreview-mysql-replica.mysql.database.azure.com
DB_USER=bookreviewadmin
DB_PASSWORD=<your-password>
DB_NAME=bookreview
DB_PORT=3306
PORT=3001
NODE_ENV=production
ENVEOF

npm install
pm2 start server.js --name bookreview-api
pm2 save && pm2 startup
```

**Frontend — on both web VMs:**

```bash
cd ~/book-review-app/frontend

# CRITICAL: Do NOT include /api — the code adds it automatically
cat > .env.local << 'ENVEOF'
NEXT_PUBLIC_API_URL=http://<LB-PUBLIC-IP>
NODE_ENV=production
ENVEOF

npm install
npm run build
pm2 start npm --name bookreview-web -- start
pm2 save && pm2 startup
```

**NGINX config — on both web VMs:**

```nginx
# /etc/nginx/sites-available/bookreview
server {
    listen 80;
    server_name _;

    # Frontend — Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade         $http_upgrade;
        proxy_set_header Connection      'upgrade';
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }

    # API — proxy to Internal LB (browser never sees private IP)
    location /api/ {
        proxy_pass http://10.0.4.100:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_read_timeout 60s;
    }
}
```

```bash
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/bookreview /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## 🐛 Real Issues Encountered and Fixed

> This is the most important section. These are real errors hit during deployment — not theoretical ones.

### Issue 1 — Default NGINX Page (Not the App)
**Error:** Browser shows NGINX welcome page  
**Root cause:** App never started. Default NGINX config still active.  
**Fix:** Remove default config, create app config, start app with PM2.

### Issue 2 — npm ETIMEDOUT on App VMs
**Error:** `npm ERR! code ETIMEDOUT — connect ETIMEDOUT 104.16.x.x:443`  
**Root cause:** App VMs are in private subnets — no outbound internet by default.  
**Fix:** Create Azure NAT Gateway and associate to both app subnets.

### Issue 3 — Browser ERR_CONNECTION_TIMED_OUT
**Error:** DevTools: `GET http://10.0.4.100:3001/api/books — net::ERR_CONNECTION_TIMED_OUT`  
**Root cause:** Frontend `.env.local` was set to the private LB IP. Browser on user's laptop cannot reach Azure VNet private IPs.  
**Fix:** Set `NEXT_PUBLIC_API_URL=http://<LB-PUBLIC-IP>`. NGINX proxies `/api/` internally — browser never needs the private IP.

### Issue 4 — 404 on /api/books (Double /api/)
**Error:** Requests going to `/api/api/books`  
**Root cause:** `src/services/api.js` already appends `/api` to every request. Setting URL to `http://IP/api/` caused double path.  
**Fix:** Read the code first. Set `NEXT_PUBLIC_API_URL=http://<LB-PUBLIC-IP>` — no `/api`, no trailing slash.

### Issue 5 — 500 on Register/Login (CORS)
**Error:** `POST /api/users/register → 500` | PM2 logs: `Error: CORS policy: Not allowed by server`  
**Root cause:** Backend CORS whitelist only allowed `localhost:3000`. Requests from LB public IP were rejected.  
**Fix:** Update `corsOptions` in `backend/src/server.js` to include the LB public IP.

---

## ✅ Verification Checklist

```bash
# Database tier
mysql -h bookreview-mysql.mysql.database.azure.com -u bookreviewadmin -p
USE bookreview; SHOW TABLES; SELECT COUNT(*) FROM books;

# App tier
curl http://localhost:3001/api/books       # from app-vm-1
pm2 status                                 # bookreview-api → online

# Web tier
curl http://localhost/api/books            # NGINX proxying
curl http://localhost:3000                 # Next.js direct

# Load Balancer health
# Azure Portal → both LBs → Backend Pools → all VMs → Healthy

# End-to-end
# Browser → http://<LB-PUBLIC-IP> → books load, register/login work
```

---

## 📸 Screenshots

> Add your screenshots here:

| Screenshot | Description |
|---|---|
| `architecture.png` | Azure resource group overview |
| `vnet-subnets.png` | 6 subnets in bookreview-vnet |
| `lb-public.png` | web-public-lb with healthy backend pool |
| `lb-internal.png` | app-internal-lb with healthy backend pool |
| `mysql-ha.png` | MySQL Zone Redundant HA status |
| `app-running.png` | Book Review App in browser |
| `pm2-status.png` | pm2 status on all VMs |

---

## 🧹 Cleanup

```bash
# Delete everything at once
Azure Portal → Resource Groups → bookreview-rg → Delete resource group
```

Removes: VNet, NSGs, 4 VMs, 2 LBs, NAT Gateway, MySQL Primary + Replica, Private DNS Zone.

---

## 💡 Key Learnings

1. **NGINX is a security boundary** — not just a web server. It keeps private IPs hidden from the browser by proxying API calls internally.

2. **Private VMs need NAT Gateway** — for outbound internet access without a public IP. This is the production pattern for private subnet instances.

3. **Next.js bakes env vars at build time** — any change to `.env.local` requires `npm run build` + restart. Changing the file alone does nothing.

4. **Read the application code before writing infrastructure config** — `api.js` had a comment saying "do not include /api in the URL". Reading it first would have saved a debugging session.

5. **Zone Redundant HA vs Read Replica are different** — HA is for availability (auto-failover if a zone dies). Replica is for performance (offload read queries). Production systems need both.

6. **Jump box is a feature, not a limitation** — app VMs have no public IP by design. All admin access through one controlled entry point reduces the attack surface from 4 VMs to 1.

---

## 👨‍💻 Author

**Venkatesh Gangavarapu**  
DevOps Micro Internship — Guided by [Pravin Mishra](https://github.com/pravinmishraaws)

---

## 🏷️ Tags

`Azure` `DevOps` `Three-Tier-Architecture` `NextJS` `NodeJS` `MySQL` `NGINX` `PM2` `LoadBalancer` `CloudInfrastructure` `LearningInPublic`
