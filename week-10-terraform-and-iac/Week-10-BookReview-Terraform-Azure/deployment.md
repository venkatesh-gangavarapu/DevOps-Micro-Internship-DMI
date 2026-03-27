# Deployment Guide

This document explains how the application is deployed onto the Azure VMs provisioned by Terraform.

## How Deployment Works

Application deployment is **fully automated** — no manual SSH steps are required after `terraform apply`.

When Terraform creates each VM, it passes a shell script via `custom_data` (Azure's equivalent of AWS `user_data`). The scripts execute automatically on first boot:

| VM | Script | What it does |
|----|--------|--------------|
| Web server | `scripts/frontend-userdata.sh` | Installs Node.js + Nginx, clones repo, builds Next.js frontend, starts with PM2, configures Nginx reverse proxy |
| App server | `scripts/backend-userdata.sh` | Installs Node.js, clones repo, writes `.env`, starts Node.js backend with PM2 |

Terraform injects live infrastructure values (LB IPs, DB endpoint, credentials) into the scripts at plan time using `templatefile()`, so no manual configuration of scripts is needed.

---

## Prerequisites

Before running `terraform apply`, ensure `terraform.tfvars` contains the following values that the scripts depend on:

| Variable | Used in script | Description |
|----------|---------------|-------------|
| `db_admin_username` | `backend-userdata.sh` → `DB_USER` | MySQL admin username |
| `db_admin_password` | `backend-userdata.sh` → `DB_PASS` | MySQL admin password |
| `db_name` | `backend-userdata.sh` → `DB_NAME` | Database name |

The following are injected automatically from Terraform outputs — no action needed:

| Template variable | Source | Injected into |
|-------------------|--------|---------------|
| `public_lb_ip` | `module.networking.public_lb_ip` | Both scripts — `NEXT_PUBLIC_API_URL` and `ALLOWED_ORIGINS` |
| `private_lb_ip` | `module.networking.private_lb_ip` | `frontend-userdata.sh` — Nginx proxy to internal LB |
| `db_host` | `module.database.db_endpoint` | `backend-userdata.sh` → `DB_HOST` |

---

## What Each Script Does

### `scripts/backend-userdata.sh` (App Server)

1. Updates system packages
2. Installs Node.js LTS, `mysql-client`, `nginx`, `git`
3. Clones `https://github.com/pravinmishraaws/book-review-app.git`
4. Writes `/home/ubuntu/book-review-app/backend/.env`:
   ```
   DB_HOST=<mysql-fqdn>
   DB_USER=<db_admin_username>
   DB_PASS=<db_admin_password>
   DB_NAME=<db_name>
   DB_DIALECT=mysql
   PORT=3001
   JWT_SECRET=mysecret
   ALLOWED_ORIGINS=http://<public_lb_ip>
   ```
5. Installs npm dependencies
6. Starts backend with PM2 as process `bk-backend`
7. Configures PM2 to restart on system reboot

Logs: `/var/log/backend-user-data.log`

---

### `scripts/frontend-userdata.sh` (Web Server)

1. Updates system packages
2. Installs Node.js LTS, `nginx`, `git`
3. Clones `https://github.com/pravinmishraaws/book-review-app.git`
4. Writes `/home/ubuntu/book-review-app/frontend/.env.local`:
   ```
   NEXT_PUBLIC_API_URL=http://<public_lb_ip>
   ```
5. Builds the Next.js frontend (`npm run build`)
6. Starts frontend with PM2 as process `frontend` on port 3000
7. Configures Nginx as a reverse proxy:
   - `GET /api/*` → proxied to `http://<private_lb_ip>:3001/api/` (internal LB → app server)
   - `GET /*` → proxied to `http://localhost:3000` (Next.js frontend)
8. Enables and starts Nginx

Logs: `/var/log/frontend-user-data.log`

---

## Post-Deployment Verification

Scripts take approximately **5–10 minutes** to complete after `terraform apply` finishes (VM boot + package installs + npm build).

### 1. Check Terraform outputs
```bash
terraform output
```
Note the `public_lb_ip` value — this is the application entry point.

### 2. Verify the app is running
Open in a browser:
```
http://<public_lb_ip>
```
Test login/register and API-backed pages to confirm end-to-end connectivity.

### 3. Check frontend VM (web server)
```bash
# Get web server public IP
terraform output webserver_pub_ip

# SSH into web server
ssh -i ~/.ssh/book-review-key ubuntu@<webserver_pub_ip>

# Check user_data completed
sudo cat /var/log/frontend-user-data.log

# Check PM2 status
pm2 status

# Check Nginx
sudo nginx -t
sudo systemctl status nginx --no-pager
```

### 4. Check backend VM (app server)
The app server has no public IP. SSH via the web server as a jump host:
```bash
ssh -i ~/.ssh/book-review-key -J ubuntu@<webserver_pub_ip> ubuntu@<appserver_prvt_ip>

# Check user_data completed
sudo cat /var/log/backend-user-data.log

# Check PM2 status
pm2 status
pm2 logs bk-backend --lines 100
```

### 5. Verify `/api/` proxy
From inside the web server, confirm the internal LB and backend are reachable:
```bash
# Check internal LB health (replace with your private_lb_ip)
curl -v http://<private_lb_ip>:3001/api/
```

---

## Re-running Scripts (if needed)

The scripts are only executed once automatically at first boot. To re-run them manually after the VM is already running:

```bash
# On the web server
sudo bash /var/lib/waagent/CustomData.bin

# Or re-apply Terraform to force VM recreation
terraform taint module.compute.azurerm_linux_virtual_machine.web_server
terraform apply
```

> **Note:** `terraform taint` marks the VM for recreation on the next `apply`. This will delete and recreate the VM and re-run user_data.

---

## Common Troubleshooting

| Symptom | Check | Fix |
|---------|-------|-----|
| App not loading at `public_lb_ip` | `pm2 status` on web server | Wait for user_data to finish; check `/var/log/frontend-user-data.log` |
| `/api/` requests failing | `pm2 logs bk-backend` on app server | Verify `.env` has correct `DB_HOST`; check DB connectivity |
| PM2 process not running | `pm2 status` | `pm2 restart frontend` or `pm2 restart bk-backend` |
| Nginx fails config test | `sudo nginx -t` | Check syntax in `/etc/nginx/sites-available/book-review` |
| CORS errors in browser | Backend `.env` `ALLOWED_ORIGINS` | Ensure it matches `http://<public_lb_ip>` exactly |
| DB connection refused | App server → MySQL connectivity | Verify app NSG allows 3306 outbound; check `db_host` in `.env` |
| `Permission denied` on SSH | SSH key | Ensure private key matches `ssh_public_key` in `terraform.tfvars` |

---

## Author

**Venkatesh Gangavarapu**

- LinkedIn: [www.linkedin.com/in/venkatesh-gangavarapu](https://www.linkedin.com/in/venkatesh-gangavarapu)
- GitHub: [www.github.com/venkatesh-gangavarapu](https://www.github.com/venkatesh-gangavarapu)
