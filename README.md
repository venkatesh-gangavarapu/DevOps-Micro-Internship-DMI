# DevOps Micro Internship (DMI)

A structured 8-week DevOps learning program covering production operations, cloud deployments, containerization, CI/CD automation, and enterprise-grade three-tier architecture on AWS and Azure.

## Program Overview

| Week | Focus Area | Key Technologies |
|------|-----------|-----------------|
| [Week 1](#week-1-foundations--mindset) | Foundations & Mindset | Planning, Goal Setting |
| [Week 2](#week-2-production-operations--linux) | Production Operations & Linux | Linux, Nginx, systemctl, Bash |
| [Week 3](#week-3-project-deep-dive) | Project Deep Dive | CodeTrack |
| [Week 4](#week-4-portfolio--job-sites) | Portfolio & Job Sites | HTML, CSS, JavaScript |
| [Week 5](#week-5-consolidated-revision) | Consolidated Revision | AWS EC2, Git, CI/CD |
| [Week 6](#week-6-docker-cicd--cloud-deployment) | Docker, CI/CD & Cloud | Docker, Node.js, Next.js, Azure Pipelines, AWS S3 |
| [Week 8](#week-8-azure-advanced-architecture) | Azure Advanced Architecture | Azure VNet, Load Balancers, MySQL Flexible Server |

---

## Week 1: Foundations & Mindset

**Path:** `dmi-week1/`

Establishing the right mindset, discipline, and systems thinking before diving into technical content.

- 7 structured assignments covering beliefs, objectives, metrics, and personal planning
- 5-month career roadmap development
- Weekly reflection system for continuous improvement

**Key Takeaway:** Consistency beats intensity; systems reduce reliance on motivation.

---

## Week 2: Production Operations & Linux

**Path:** `dmi-week2/`

Real-world production operations and Linux system administration through structured drills.

### Production Ops Drills (`production-ops/`)

A 6-phase production readiness framework:

| Phase | Focus |
|-------|-------|
| Phase 1 | Network validation & access control |
| Phase 2 | Service health checks with systemd |
| Phase 3 | Log analysis & request tracing |
| Phase 4 | System resource & performance monitoring |
| Phase 5 | Config & content integrity validation |
| Phase 6 | Incident simulation & recovery drills |

**Tools:** `systemctl`, `journalctl`, `curl`, `ss`, `lsof`, `ps`, `top`

### Deployments

- **Professional Website** — Static site served via Nginx on Ubuntu VM
- **React App on Nginx** — Production React build deployed behind Nginx reverse proxy on Ubuntu VM

---

## Week 3: Project Deep Dive

**Path:** `dmi-week3/`

- **CodeTrack** — In-progress project placeholder

---

## Week 4: Portfolio & Job Sites

**Path:** `dmi-week4/`

- **Pravin Mishra Portfolio** — Personal portfolio website
- **GottoJob** — Static job listing/aggregation website

**Stack:** HTML, CSS, JavaScript

---

## Week 5: Consolidated Revision

**Path:** `dmi-week5/`

Consolidating weeks 1–4 with a practitioner focus across five domains:

1. **Linux System Administration** — Process management, log analysis, networking
2. **Git & Branching Strategy** — Feature branches, PRs, clean commit history
3. **AWS Cloud Deployment** — EC2, SSH, security groups
4. **CI/CD Pipeline Automation** — Automated build and deploy workflows
5. **Production Debugging** — Root cause analysis and incident response

**Shift:** From learner to practitioner; from theory to deployment.

---

## Week 6: Docker, CI/CD & Cloud Deployment

**Path:** `dmi-week6/`

### Book Review App — Full-Stack Three-Tier Application

**Path:** `dmi-week6/book-review-app/`

A production-grade full-stack application with Docker Compose orchestration.

**Architecture:**
```
Next.js Frontend (port 3000)
       ↓
Express.js Backend (port 3001)
       ↓
MySQL 8.0 Database (port 3306)
```

**Tech Stack:**
- **Frontend:** Next.js, Tailwind CSS, Axios, React Context API
- **Backend:** Node.js, Express.js, JWT authentication, bcrypt, Sequelize ORM
- **Database:** MySQL 8.0
- **Containerization:** Docker, Docker Compose
- **Infrastructure as Code:** Ansible playbooks
- **CI/CD:** Azure Pipelines (`azure-pipeline.yaml`)

**Key Files:**
```
book-review-app/
├── frontend/               # Next.js application
├── backend/                # Node.js/Express REST API
├── docker-compose.yml      # Multi-container orchestration
├── ansible/site.yml        # Ansible deployment playbooks
└── azure-pipeline.yaml     # Azure DevOps CI/CD pipeline
```

**Run locally:**
```bash
cd dmi-week6/book-review-app
docker compose up -d
# Frontend: http://localhost:3000
# Backend:  http://localhost:3001
```

### Static Website on AWS S3

**Path:** `dmi-week6/static-website-s3/`

Portfolio and static site hosted on AWS S3 with static website hosting enabled.

---

## Week 8: Azure Advanced Architecture

**Path:** `dmi-week8/`

Enterprise-grade deployments on Microsoft Azure with high availability and network isolation.

### Assignment 1: React App with Docker

**Path:** `dmi-week8/my-react-app/`

- Multi-stage Docker build: Node.js 18 build stage → NGINX serve stage
- Optimized production image using Alpine base

```dockerfile
# Build stage: Node 18 Alpine
# Serve stage: NGINX Alpine
```

### Assignment 2: Azure Three-Tier Architecture

**Path:** `dmi-week8/azure-three-tier-architecture/`

Foundational three-tier network design on Azure.

**Network Architecture:**
```
Internet
   ↓
Azure Public Load Balancer
   ↓
Web Tier Subnet (Public) — NGINX VMs
   ↓
App Tier Subnet (Private) — Node.js VMs
   ↓
DB Tier Subnet (Private) — Azure MySQL Flexible Server
```

**Azure Resources:**
- Virtual Network (VNet) with 3 isolated subnets
- Network Security Groups (NSGs) per subnet
- Public Load Balancer with health probes
- Internal Load Balancer for App tier
- Azure Bastion for secure SSH (no public IP on VMs)
- NAT Gateway for private VM outbound access

### Assignment 3: EpicBook Full-Stack Deployment

**Path:** `dmi-week8/epicbook-azure-deployment/`

Full-stack application deployed on Azure with managed database.

**Components:**
- Azure VM (Ubuntu 22.04 LTS) — App server with NGINX + PM2
- Azure MySQL Flexible Server — Managed relational database with private VNet integration
- NGINX reverse proxy — Security boundary and SSL termination

### Assignment 4: Production Three-Tier Deployment

**Path:** `dmi-week8/book-review-app/`

Production-grade Book Review App on Azure with full HA and zone redundancy.

**Architecture:**
```
Public Internet
      ↓
Azure Public Load Balancer (Standard SKU)
      ↓
[Web VM 1] [Web VM 2]  ← NGINX + Next.js (Zone 1 & 2)
      ↓ /api proxy
Azure Internal Load Balancer
      ↓
[App VM 1] [App VM 2]  ← Node.js/Express + PM2 (private subnet)
      ↓ port 3306
Azure MySQL Flexible Server (Zone-Redundant HA + Auto-Failover)
```

**High Availability Features:**
- Zone-redundant VMs across multiple availability zones
- Load balancer health probes (5-second intervals, auto-remove unhealthy VMs)
- MySQL zone-redundant HA with auto-failover
- PM2 auto-restart for crashed Node.js processes
- NAT Gateway for private VM outbound internet access

---

## Tech Stack Summary

### Frontend
- React 18/19, Next.js (SSR + dynamic routing)
- Tailwind CSS, Axios

### Backend
- Node.js 18 LTS, Express.js
- JWT authentication, bcrypt, Sequelize ORM, mysql2

### Databases
- MySQL 8.0 (containerized & managed)
- Azure MySQL Flexible Server (private VNet integration)

### Containerization
- Docker (multi-stage builds, Alpine optimization)
- Docker Compose v2 (local multi-container orchestration)
- NGINX (web server, reverse proxy, SSL termination)

### Cloud — Azure
- Virtual Networks, Subnets, NSGs
- Virtual Machines (Ubuntu 22.04 LTS, Standard_B1s)
- Public & Internal Load Balancers (Standard SKU)
- Azure MySQL Flexible Server
- Azure Bastion, NAT Gateway
- Azure Pipelines (CI/CD)

### Cloud — AWS
- EC2 instances (Ubuntu)
- S3 static website hosting

### Infrastructure as Code & Automation
- Ansible playbooks (`site.yml`)
- Azure Pipelines YAML
- Bash scripting

### Linux & System Administration
- Ubuntu 22.04 LTS
- systemctl, journalctl, Nginx, PM2
- Network tools: `ss`, `lsof`, `curl`, `netstat`

---

## Repository Structure

```
DevOps-Micro-Internship-DMI/
├── dmi-week1/                          # Foundations & Mindset
│   ├── assignments/                    # 7 core assignments
│   └── reflections/
├── dmi-week2/                          # Production Ops & Linux
│   ├── production-ops/                 # 6-phase ops drills
│   ├── professional-website-project/   # Nginx static site
│   └── react-app-deployment-ubuntu-nginx/
├── dmi-week3/                          # Project Deep Dive
│   └── CodeTrack/
├── dmi-week4/                          # Portfolio & Job Sites
│   ├── Pravin-Mishra-Portfolio-Template/
│   └── gotto_job/
├── dmi-week5/                          # Consolidated Revision
├── dmi-week6/                          # Docker, CI/CD & Cloud
│   ├── book-review-app/                # Full-stack with Docker Compose
│   ├── Pravin-Mishra-Portfolio-Template/
│   └── static-website-s3/
└── dmi-week8/                          # Azure Advanced Architecture
    ├── my-react-app/                   # React + Docker multi-stage
    ├── azure-three-tier-architecture/  # VNet + Load Balancer setup
    ├── epicbook-azure-deployment/      # Full-stack on Azure
    └── book-review-app/               # Production HA deployment
```

---

## Key Concepts Covered

- **Production Operations:** On-call mindset, incident response, log analysis, health checks
- **Linux Administration:** Process management, service monitoring, networking, performance tuning
- **Containerization:** Docker image optimization, multi-stage builds, Docker Compose orchestration
- **CI/CD Automation:** Azure Pipelines, Ansible configuration management
- **Cloud Architecture:** Three-tier design, network isolation, security groups, managed services
- **High Availability:** Load balancing, health probes, zone redundancy, auto-failover
- **Security:** NSGs, private subnets, Azure Bastion, JWT authentication, CORS, reverse proxy
- **Database Management:** MySQL on Docker, Azure MySQL Flexible Server, ORM patterns

---

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Node.js 18 LTS
- Azure CLI (for Azure deployments)
- AWS CLI (for AWS deployments)

### Run the Book Review App (Week 6)

```bash
cd dmi-week6/book-review-app

# Copy environment files
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Start all services
docker compose up -d

# Access the app
# Frontend: http://localhost:3000
# Backend API: http://localhost:3001
```

### Explore Production Ops Drills (Week 2)

```bash
cd dmi-week2/production-ops
# Follow phase-by-phase guides in each phase directory
```

---

## Instructor

**Pravin Mishra** — DevOps Micro Internship Program

---

*Each week directory contains a detailed README with step-by-step guides, architecture diagrams, troubleshooting notes, and deployment commands.*
