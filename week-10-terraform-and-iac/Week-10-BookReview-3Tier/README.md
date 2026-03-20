<div align="center">

# Week 10 — Assignment 5: Book Review App — Production 3-Tier Architecture

### DevOps Micro Internship · Venkatesh Gangavarapu

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![RDS](https://img.shields.io/badge/RDS_MySQL-Multi--AZ-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude_Code-AI_Copilot-6B21A8?style=for-the-badge&logo=anthropic&logoColor=white)
![Status](https://img.shields.io/badge/Assignment-Completed-22C55E?style=for-the-badge)

</div>

---

## 🎯 Objective

Deploy the **Book Review App** (Next.js + Node.js + MySQL) in a fully production-grade 3-tier AWS architecture using Terraform — with Agentic AI (Claude Code) as the DevOps copilot.

---

## 🏗️ Architecture

```
Internet
     │
[ Public ALB ] ──── HTTP :80 ──► Next.js
     │
┌────▼─────────────────────────────────────────────────────────┐
│                    VPC  10.0.0.0/16                          │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  WEB TIER (Public Subnets)                           │    │
│  │  10.0.1.0/24 (AZ-a)  ·  10.0.2.0/24 (AZ-b)         │    │
│  │  EC2: Next.js   ←──── Public ALB (:80)               │    │
│  │  SG: allow :80 from ALB SG only                      │    │
│  └────────────────────────┬─────────────────────────────┘    │
│                           │ Internal API :3001                │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  APP TIER (Private Subnets)                          │    │
│  │  10.0.3.0/24 (AZ-a)  ·  10.0.4.0/24 (AZ-b)         │    │
│  │  EC2: Node.js   ←──── Internal ALB (:3001)           │    │
│  │  SG: allow :3001 from Internal ALB SG only           │    │
│  └────────────────────────┬─────────────────────────────┘    │
│                           │ MySQL :3306                       │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  DB TIER (Private Subnets)                           │    │
│  │  10.0.5.0/24 (AZ-a)  ·  10.0.6.0/24 (AZ-b)         │    │
│  │  RDS MySQL Primary (Multi-AZ) + Read Replica         │    │
│  │  SG: allow :3306 from App Tier SG only               │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

---

## 📁 Terraform Code Structure

```
terraform/
├── main.tf               ← VPC, 6 subnets, IGW, route tables
├── security-groups.tf    ← 5 tier-specific SGs (Web, App, DB, Public ALB, Internal ALB)
├── alb.tf                ← Public ALB + Internal ALB + listeners + target groups
├── ec2.tf                ← Web tier + App tier EC2 instances
├── rds.tf                ← RDS MySQL Multi-AZ + Read Replica
├── variables.tf          ← Region, instance types, DB credentials
├── outputs.tf            ← ALB DNS, RDS endpoint, app URL
└── user-data/
    ├── web-tier.sh       ← Next.js setup + Nginx proxy
    └── app-tier.sh       ← Node.js setup + app start
```

---

## 🌐 Subnet CIDR Plan

| Tier | CIDR | AZ | Purpose |
|---|---|---|---|
| Web (Public) | 10.0.1.0/24 | ap-south-1a | Next.js — AZ1 |
| Web (Public) | 10.0.2.0/24 | ap-south-1b | Next.js — AZ2 |
| App (Private) | 10.0.3.0/24 | ap-south-1a | Node.js — AZ1 |
| App (Private) | 10.0.4.0/24 | ap-south-1b | Node.js — AZ2 |
| DB (Private) | 10.0.5.0/24 | ap-south-1a | RDS Primary |
| DB (Private) | 10.0.6.0/24 | ap-south-1b | RDS Read Replica |

---

## 🔐 Security Group Design

| SG | Allows | Source |
|---|---|---|
| Public ALB SG | :80 inbound | 0.0.0.0/0 |
| Web Tier EC2 SG | :80 | Public ALB SG only |
| Internal ALB SG | :3001 | Web Tier EC2 SG only |
| App Tier EC2 SG | :3001 | Internal ALB SG only |
| DB Tier RDS SG | :3306 | App Tier EC2 SG only |

---

## 🚀 Deploy

```bash
cd terraform/

terraform init
terraform plan    # ~25 resources to add
terraform apply   # Type 'yes'
terraform output  # Get ALB DNS + RDS endpoint
```

**Access the app:**
```
http://<public-alb-dns>
```

**Destroy:**
```bash
terraform destroy    # RDS takes ~5 mins to terminate
```

---

## 🤖 How Claude Code Was Used

| Task | Claude Code Prompt | Outcome |
|---|---|---|
| Architecture design | "Design a 3-tier AWS VPC for a Next.js + Node.js + MySQL app" | Generated full subnet layout + SG design |
| Security audit | "Review my SG rules — is traffic flowing correctly?" | Caught App tier SG pointing to wrong source |
| Debugging | "Terraform error: cannot find mysql version 8.0.35" | Fixed engine_version to "8.0" |
| user_data | "Generate Ubuntu bootstrap script for Next.js with Nginx" | Complete working script generated |
| Improvements | "Make this more production-ready" | Suggested HTTPS, NAT GW, CloudWatch alarms |

---

## ✅ Tasks Completed

| Task | Description | Status |
|---|---|:---:|
| Task 1 | Architecture report + Terraform code structure | ✅ |
| Task 2 | Screenshots — EC2, RDS, app UI, API integration | ✅ |
| Task 3 | LinkedIn post published | ✅ |

---

## 💡 Key Learnings

**1. Multi-AZ ≠ Read Replica.**
Multi-AZ = availability (automatic failover, standby not readable).
Read Replica = scale (readable, not a failover target). Both serve different purposes.

**2. Internal ALB is the correct source for App tier SG rules.**
Traffic from the frontend reaches the backend through the Internal ALB — not directly from the Web EC2s. The App tier SG must reference the Internal ALB SG, not the Web tier EC2 SG.

**3. AI copilot = faster iteration, not less thinking.**
Claude Code caught security group misconfigurations I missed, generated boilerplate instantly, and suggested improvements I hadn't considered. But every suggestion was reviewed and understood before applying. That's the right way to work with Agentic AI.

---

## 🔗 Navigation

← [Assignment 4 — EpicBook EC2 + RDS](../Week-10-EpicBook-AWS/)

[↑ Back to Main README](../README.md)

---

<div align="center">
<sub>DevOps Micro Internship · Week 10 · Assignment 5 · Book Review 3-Tier AWS · Venkatesh Gangavarapu</sub>
</div>
