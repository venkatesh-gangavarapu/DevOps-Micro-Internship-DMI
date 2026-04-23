# Week 14 — Assignment 2: Single-Stage vs Multi-Stage Docker Build for React App

> Demonstrates the difference between a **single-stage baseline** and an optimized **multi-stage Docker build** for a React application — reducing image size by ~98% and improving security and CI/CD performance.

---

## The Core Concept

```
Single-Stage (baseline):
┌─────────────────────────────────────────────┐
│  node:18 (600MB+)                           │
│  + source code                              │
│  + node_modules (hundreds of MB)            │
│  + build tools (npm, webpack, babel...)     │
│  + compiled build/ output                  │
│                                             │
│  Final image: ~1.2GB  ← ships ALL of this  │
└─────────────────────────────────────────────┘

Multi-Stage (production):
┌──────────────────────┐    ┌──────────────────────┐
│  Stage 1 — Builder   │    │  Stage 2 — Runtime   │
│  node:18-alpine      │───►│  nginx:alpine        │
│  npm ci              │    │  ONLY build/ output  │
│  npm run build       │    │                      │
│  → build/ directory  │    │  Final image: ~25MB  │
│  (DISCARDED)         │    │                      │
└──────────────────────┘    └──────────────────────┘
```

---

## Project Structure

```
single-and-multi-stage-docker/
├── Dockerfile            # Multi-stage production build
├── Dockerfile.single     # Single-stage baseline for comparison
├── .dockerignore         # Excludes node_modules, build, .git etc
├── nginx.conf            # React SPA nginx config reference
├── terraform/
│   ├── providers.tf      # Azure provider
│   └── main.tf           # VM + NSG (ports 22, 80, 3000)
├── .gitignore
└── README.md
```

> The React source code lives at:
> https://github.com/pravinmishraaws/my-react-app
> Clone it and copy the Dockerfiles into the repo root.

---

## Prerequisites

- Docker VM running from Assignment 1 (or any VM with Docker installed)
- Azure CLI + Terraform (if provisioning fresh VM)
- Port 80 and 3000 open in NSG

---

## Quick Start

### On the VM

```bash
# Clone the React app
git clone https://github.com/pravinmishraaws/my-react-app.git
cd my-react-app

# Copy Dockerfiles from this repo into the React app directory
# Then build and compare
```

### Build Single-Stage Baseline

```bash
docker build -f Dockerfile.single -t react-single:latest .
docker images react-single:latest
docker run -d --name react-single -p 3000:3000 react-single:latest
# Visit: http://<public_ip>:3000
```

### Build Multi-Stage Production

```bash
docker build -t react-multi:latest .
docker images react-multi:latest
docker run -d --name react-multi -p 80:80 react-multi:latest
# Visit: http://<public_ip>
```

### Compare Sizes

```bash
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep react
```

---

## Image Size Analysis

| Image | Base | What It Contains | Approx Size |
|---|---|---|---|
| `react-single` | node:18 | Node.js + npm + node_modules + source + build tools + build output | ~1.2 GB |
| `react-multi` | nginx:alpine | nginx + compiled build/ files only | ~25 MB |
| **Reduction** | | | **~98%** |

---

## Why Multi-Stage Builds Matter

**Security — Smaller Attack Surface**
The single-stage image ships Node.js, npm, webpack, babel, and hundreds of node_modules packages to production. Every package is a potential CVE. The multi-stage image ships only nginx and static HTML/CSS/JS files. There is nothing to exploit in a build tool that is not present.

**CI/CD Speed — Faster Push and Pull**
A 25MB image pushes to a registry in seconds. A 1.2GB image can take minutes. Across hundreds of deployments — feature releases, hotfixes, rollbacks — this difference compounds significantly.

**Layer Caching — Faster Rebuilds**
Copying `package.json` and `package-lock.json` first, before the rest of the source, means Docker only re-runs `npm install` when dependencies actually change. If only a component file changes, the `npm install` layer is served from cache and the rebuild takes seconds.

**Principle of Least Privilege**
Production containers should contain only what is needed to run the application. Build tools, compilers, and package managers are development concerns. They have no business being in a production runtime image.

---

## Files in This Repo

### `Dockerfile` — Multi-Stage Production Build
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --silent
COPY . .
RUN npm run build

FROM nginx:alpine AS runtime
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build /usr/share/nginx/html
# nginx SPA config + healthcheck included
EXPOSE 80
```

### `Dockerfile.single` — Single-Stage Baseline
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
RUN npm install -g serve
EXPOSE 3000
CMD ["serve", "-s", "build", "-l", "3000"]
```

### `.dockerignore`
```
node_modules
build
.git
.env
.env.local
```

---

## Useful Commands

```bash
# Build both images
docker build -f Dockerfile.single -t react-single:latest .
docker build -t react-multi:latest .

# Compare sizes
docker images | grep react

# Run single-stage on port 3000
docker run -d --name react-single -p 3000:3000 react-single:latest

# Run multi-stage on port 80
docker run -d --name react-multi -p 80:80 react-multi:latest

# Test React Router (should return 200 on all routes)
curl -I http://localhost/
curl -I http://localhost/about

# View build logs
docker logs react-multi

# Clean up
docker stop react-single react-multi
docker rm react-single react-multi
docker rmi react-single:latest react-multi:latest
```

---

## Teardown

```bash
cd terraform/
terraform destroy
```

---

## Part of DevOps Micro Internship

Week 14, Assignment 2 — **DevOps Micro Internship** guided by [Pravin Mishra](https://github.com/pravinmishraaws).

---

*Venkatesh Gangavarapu[www.linkedin.com/in/venkatesh-gangavarapu] — DevOps Engineer*
