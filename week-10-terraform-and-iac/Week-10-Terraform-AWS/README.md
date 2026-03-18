<div align="center">

# Week 10 — Assignment 2: AWS EC2 in Custom VPC

### DevOps Micro Internship · Venkatesh Gangavarapu

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![EC2](https://img.shields.io/badge/EC2-Ubuntu_20.04-orange?style=for-the-badge&logo=amazon-aws)
![Status](https://img.shields.io/badge/Assignment-Completed-22C55E?style=for-the-badge)

</div>

---

## 🎯 Objective

Automate the deployment of an AWS EC2 instance inside a **custom VPC** with public and private subnets using Terraform — no manual console clicks.

---

## 🏗️ Architecture

```
Internet
    │
    ▼
┌──────────────────────────────────────────────┐
│          Internet Gateway (IGW)              │
└──────────────────┬───────────────────────────┘
                   │
┌──────────────────▼───────────────────────────┐
│           Custom VPC  10.0.0.0/16            │
│                                              │
│  ┌───────────────────┐  ┌─────────────────┐  │
│  │   Public Subnet   │  │ Private Subnet  │  │
│  │   10.0.1.0/24     │  │  10.0.2.0/24    │  │
│  │                   │  │  (no IGW route) │  │
│  │  ┌─────────────┐  │  │                 │  │
│  │  │ EC2 Ubuntu  │  │  │                 │  │
│  │  │ Public IP ✓ │  │  │                 │  │
│  │  │ SG: 22 + 80 │  │  │                 │  │
│  │  │ Nginx ✓     │  │  │                 │  │
│  │  └─────────────┘  │  │                 │  │
│  └───────────────────┘  └─────────────────┘  │
│         Route Table ──────────────► IGW      │
└──────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
Week-10-Terraform-AWS/
├── README.md           ← This file
└── terraform/
    ├── main.tf         ← All 9 AWS resources
    ├── variables.tf    ← Region, instance type, etc.
    ├── outputs.tf      ← Public IP + DNS outputs
    └── provider.tf     ← AWS provider config
```

---

## ⚙️ Resources Defined

| # | Terraform Resource | Purpose |
|---|---|---|
| 1 | `data.aws_ami` | Dynamic Ubuntu 20.04 AMI lookup — region-portable |
| 2 | `aws_vpc` | Custom VPC — 10.0.0.0/16 |
| 3 | `aws_subnet` (public) | Public subnet — 10.0.1.0/24, auto-assign public IP |
| 4 | `aws_subnet` (private) | Private subnet — 10.0.2.0/24 |
| 5 | `aws_internet_gateway` | IGW attached to VPC |
| 6 | `aws_route_table` | Route table — 0.0.0.0/0 → IGW |
| 7 | `aws_route_table_association` | Associates route table with public subnet |
| 8 | `aws_security_group` | Allows inbound SSH (22) and HTTP (80) |
| 9 | `aws_instance` | Ubuntu 20.04, t2.micro, Nginx via user_data |

---

## 🚀 Full Lifecycle

### Prerequisites
```bash
aws configure          # Set Access Key, Secret, Region
aws sts get-caller-identity   # Verify credentials
terraform --version   # Confirm Terraform installed
```

### Deploy
```bash
cd terraform/

terraform init       # Download AWS provider
terraform plan       # Preview: 9 to add, 0 to change, 0 to destroy
terraform apply      # Type 'yes' — provisions all resources
```

### Validate
```bash
# Get public IP and DNS
terraform output

# Check via AWS CLI
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=terraform-web-ec2" \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}"

# Test HTTP (wait ~90s for user_data to complete)
curl http://<public-ip>

# SSH access
ssh -i your-key.pem ubuntu@<public-ip>
```

### Destroy
```bash
terraform destroy    # Type 'yes'
# Destroy complete! Resources: 9 destroyed.
```

---

## 📤 Outputs

```
ec2_public_ip  = "XX.XX.XX.XX"
ec2_public_dns = "ec2-XX-XX-XX-XX.compute-1.amazonaws.com"
```

---

## ✅ Tasks Completed

| Task | Description | Status |
|---|---|:---:|
| Task 1 | Provision custom VPC + EC2 via Terraform | ✅ |
| Task 2 | Validate EC2 running + Nginx accessible in browser | ✅ |
| Task 3 | Submit screenshots + reflection | ✅ |

---

## 💡 Key Learnings

**1. AWS networking is fully explicit.**
Every hop must be declared: VPC → Subnet → IGW → Route Table → Association.
Azure handles some of this implicitly. AWS gives you full control but requires every connection to be wired.

**2. Dynamic AMI data sources are essential.**
AMI IDs are region-specific. Hardcoding them breaks portability.
Using `data.aws_ami` with filters dynamically resolves the correct image for any region.

**3. user_data bootstraps EC2 on first boot.**
Nginx was installed automatically — no manual SSH needed.
Note: EC2 shows "running" before user_data completes. Wait ~90 seconds before testing HTTP.

---

## ⚡ AWS vs Azure Comparison

| Concept | AWS | Azure |
|---|---|---|
| Network | VPC + IGW + Route Table (explicit) | VNet + Subnet (implicit routing) |
| VM | `aws_instance` | `azurerm_linux_virtual_machine` |
| Public IP | `associate_public_ip_address = true` | `azurerm_public_ip` (separate resource) |
| Bootstrap | `user_data` script | `custom_data` or VM extensions |
| AMI/Image | Data source — region-specific | `source_image_reference` block |

---

## ⚠️ Issues & Solutions

| Issue | Root Cause | Fix |
|---|---|---|
| Wrong AMI ID on apply | AMI IDs are region-specific | Use `data.aws_ami` data source |
| Browser connection refused | user_data still running | Wait 90s after apply, then retry |
| VPC failed to destroy | IGW still attached (timing) | Re-run `terraform destroy` |

---

## 🔗 Navigation

← [Assignment 1 — Azure VM](../Week-10-Terraform-Azure/)
← [Week 09 — Agentic AI DevOps](../Week-09-Agentic-AI-Claude-Code/)
→ Week 11 — Coming Soon

[↑ Back to Main README](../README.md)

---

<div align="center">
<sub>DevOps Micro Internship · Week 10 · Assignment 2 · Terraform on AWS · Venkatesh Gangavarapu</sub>
</div>
