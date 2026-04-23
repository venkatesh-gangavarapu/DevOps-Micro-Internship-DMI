# Week 14 — Assignment 1: Dockerized Static Website on Azure VM

> Ubuntu 22.04 VM provisioned on Azure with Docker installed automatically via **cloud-init**, serving a static website inside an **Nginx container** on port 80.

---

## What This Project Does

```
terraform apply
      │
      ▼
Azure VM (Ubuntu 22.04)
      │
      │ cloud-init runs at first boot
      ▼
Docker installed + enabled automatically
      │
      │ manual steps on VM
      ▼
git clone Azure-Static-Website
docker build -t static-site:latest .
docker run -d -p 80:80 static-site:latest
      │
      ▼
http://<public_ip>  →  Static site live in browser
```

---

## Project Structure

```
docker-fundamentals/
├── terraform/
│   ├── providers.tf      # Azure provider config
│   ├── main.tf           # VM + VNet + NSG + cloud-init attachment
│   └── cloud-init.yml    # Installs Docker at VM first boot
├── Dockerfile            # Builds static site image using nginx:alpine
├── .gitignore
└── README.md
```

> The static site source code lives at:
> https://github.com/pravinmishraaws/Azure-Static-Website
> It is cloned directly on the VM — not stored in this repo.

---

## Prerequisites

- Azure CLI authenticated (`az login`)
- Terraform >= 1.0 installed
- SSH rsa key at `~/.ssh/id_rsa`

---

## Deployment Guide

### Step 1 — Provision VM with Docker via Cloud-Init

```bash
cd terraform/
terraform init
terraform plan
terraform apply
# Note the public_ip from output
```

Cloud-init runs automatically at first boot and installs Docker. Wait 2–3 minutes after the VM is up before SSH-ing in.

### Step 2 — Verify Docker Installed

```bash
ssh azureuser@<public_ip>

# Check cloud-init finished
sudo cloud-init status
# Expected: status: done

# Verify Docker
docker --version
docker ps
```

> If you see `permission denied` on docker commands, log out and back in:
> ```bash
> exit
> ssh azureuser@<public_ip>
> ```

### Step 3 — Clone the Static Site Repo

```bash
git clone https://github.com/pravinmishraaws/Azure-Static-Website.git
cd Azure-Static-Website
```

### Step 4 — Copy the Dockerfile into the Repo

```bash
# Copy Dockerfile from this repo OR paste it manually
cat > Dockerfile << 'EOF'
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY . /usr/share/nginx/html
EXPOSE 80
EOF
```

### Step 5 — Build and Run the Container

```bash
# Build the image
docker build -t static-site:latest .

# Run container on port 80
docker run -d \
  --name static-site \
  -p 80:80 \
  --restart unless-stopped \
  static-site:latest

# Verify running
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE                PORTS                  NAMES
abc123def456   static-site:latest   0.0.0.0:80->80/tcp     static-site
```

### Step 6 — Verify in Browser

```bash
# From terminal
curl http://<public_ip>

# Or open in browser
http://<public_ip>
```

---

## Dockerfile Explained

```dockerfile
FROM nginx:alpine          # base image: nginx on Alpine Linux (~25MB)
RUN rm -rf /usr/share/nginx/html/*   # remove default nginx page
COPY . /usr/share/nginx/html         # copy static site files into web root
EXPOSE 80                  # document that container listens on port 80
```

---

## Cloud-Init Explained

Cloud-init runs once at first boot — before you SSH in. It handles:

```yaml
packages:
  - docker.io              # install Docker from Ubuntu repos

runcmd:
  - systemctl enable docker   # start Docker on every reboot
  - systemctl start docker    # start Docker now
  - usermod -aG docker azureuser  # allow azureuser to run docker without sudo
```

This means zero manual install steps. The VM arrives with Docker ready to use.

---

## Useful Commands

```bash
# List all images
docker images

# List running containers
docker ps

# List all containers including stopped
docker ps -a

# View container logs
docker logs static-site

# Stop container
docker stop static-site

# Remove container
docker rm static-site

# Remove image
docker rmi static-site:latest

# Rebuild and restart after code change
docker stop static-site && docker rm static-site
docker build -t static-site:latest .
docker run -d --name static-site -p 80:80 --restart unless-stopped static-site:latest
```

---

## Teardown

```bash
cd terraform/
terraform destroy
```

---

## Part of DevOps Micro Internship

Week 14, Assignment 1 — **DevOps Micro Internship** guided by [Pravin Mishra](https://github.com/pravinmishraaws).

---

*Venkatesh Gangavarapu[www.linkedin.com/venkatesh-gangavarapu] — DevOps Engineer*
