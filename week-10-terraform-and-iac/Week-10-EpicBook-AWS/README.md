<div align="center">

# Week 10 — Assignment 4: EpicBook on AWS EC2 + RDS

### DevOps Micro Internship · Venkatesh Gangavarapu

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![MySQL](https://img.shields.io/badge/RDS_MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Status](https://img.shields.io/badge/Assignment-Completed-22C55E?style=for-the-badge)

</div>

---

## 🎯 Objective

Deploy the **EpicBook** full-stack e-commerce application on AWS using Terraform — EC2 in a public subnet serving the app, RDS MySQL in a private subnet storing the data.

---

## 🏗️ Architecture

```
Internet
    │
[ Internet Gateway ]
    │
┌───▼──────────────────────────────────────────────────┐
│                  VPC  10.0.0.0/16                    │
│                                                       │
│  ┌──────────────────────┐                             │
│  │  Public Subnet        │  ← Route Table → IGW       │
│  │  10.0.1.0/24          │                             │
│  │  ┌────────────────┐  │                             │
│  │  │ EC2 Ubuntu 22  │  │                             │
│  │  │ t2.micro       │──┼──────────────────────┐     │
│  │  │ Node.js+Nginx  │  │                      │     │
│  │  │ SG: 22 + 80    │  │                      │     │
│  │  └────────────────┘  │                      ▼     │
│  └──────────────────────┘   ┌────────────────────────┐│
│                              │  RDS MySQL             ││
│  ┌──────────────────────┐   │  db.t3.micro           ││
│  │ Private Subnet (AZ1) │   │  public: false         ││
│  │ 10.0.2.0/24          │   │  SG: 3306 from EC2 SG  ││
│  │ Private Subnet (AZ2) │   └────────────────────────┘│
│  │ 10.0.3.0/24          │                              │
│  └──────────────────────┘                              │
└──────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
Week-10-EpicBook-AWS/
├── README.md
└── terraform/
    ├── main.tf         ← All 14 AWS resources
    ├── variables.tf    ← Region, DB creds, key pair
    ├── outputs.tf      ← EC2 IP, RDS endpoint, app URL
    └── provider.tf     ← AWS provider config
```

---

## ⚙️ Terraform Resources (14 total)

| # | Resource | Purpose |
|---|---|---|
| 1 | `data.aws_ami` | Dynamic Ubuntu 22.04 AMI lookup |
| 2 | `aws_vpc` | Custom VPC — 10.0.0.0/16 |
| 3 | `aws_subnet` (public) | Public subnet 10.0.1.0/24 — EC2 |
| 4 | `aws_subnet` (private-1) | Private subnet 10.0.2.0/24 — RDS AZ1 |
| 5 | `aws_subnet` (private-2) | Private subnet 10.0.3.0/24 — RDS AZ2 |
| 6 | `aws_internet_gateway` | IGW for public internet access |
| 7 | `aws_route_table` | Public route — 0.0.0.0/0 → IGW |
| 8 | `aws_route_table_association` | Associates public RT with public subnet |
| 9 | `aws_security_group` (EC2) | Allows SSH (22) + HTTP (80) |
| 10 | `aws_security_group` (RDS) | Allows MySQL (3306) from EC2 SG only |
| 11 | `aws_db_subnet_group` | RDS subnet group — spans 2 AZs (required) |
| 12 | `aws_db_instance` | RDS MySQL 8.0, db.t3.micro, private |
| 13 | `aws_instance` | EC2 Ubuntu 22.04 t2.micro, public subnet |
| 14 | `aws_key_pair` | SSH key pair for EC2 access |

> **Key security design:** The RDS security group uses `security_groups = [aws_security_group.ec2.id]` — not a CIDR range. Only EC2 instances in that specific security group can connect to the database on port 3306.

---

## 🚀 Full Deployment

### Prerequisites
```bash
aws configure              # Set credentials + region
aws sts get-caller-identity
terraform --version
```

### Step 1 — Provision Infrastructure
```bash
cd terraform/
terraform init
terraform plan             # 14 to add
terraform apply            # Type 'yes'
terraform output           # Get EC2 IP + RDS endpoint
```

### Step 2 — SSH + Install Dependencies
```bash
ssh -i your-key.pem ubuntu@<ec2-public-ip>

sudo apt update && sudo apt upgrade -y
sudo apt install nodejs npm git nginx mysql-client -y
node -v && npm -v
```

### Step 3 — Deploy EpicBook
```bash
git clone <epicbook-repo-url>
cd <epicbook-folder>
npm install

# Create .env
cat > .env <<EOF
DB_HOST=<rds-endpoint>
DB_USER=<username>
DB_PASSWORD=<password>
DB_NAME=<dbname>
PORT=3000
EOF
```

### Step 4 — Initialise the Database
```bash
# Connect via mysql-client (from inside EC2)
mysql -h <rds-endpoint> -u <username> -p<password> <dbname> < dump.sql

# Verify
mysql -h <rds-endpoint> -u <username> -p
# SHOW DATABASES; USE <dbname>; SHOW TABLES;
```

### Step 5 — Start App + Configure Nginx
```bash
npm start &

# Nginx reverse proxy config
sudo nano /etc/nginx/sites-available/default
# Inside location / block:
# proxy_pass http://localhost:3000;
# proxy_http_version 1.1;
# proxy_set_header Host $host;

sudo nginx -t && sudo systemctl reload nginx
```

### Step 6 — Verify
```
http://<ec2-public-ip>
✅ Homepage loads
✅ Products pull from RDS MySQL
✅ Cart + checkout work end-to-end
```

### Step 7 — Destroy
```bash
terraform destroy    # 14 resources destroyed
# Note: RDS takes ~5 mins to terminate
```

---

## 📤 Outputs

```
ec2_public_ip  = "XX.XX.XX.XX"
rds_endpoint   = "epicbook-mysql.xxxx.ap-south-1.rds.amazonaws.com:3306"
app_url        = "http://XX.XX.XX.XX"
```

---

## ✅ Tasks Completed

| Task | Description | Status |
|---|---|:---:|
| Task 1 | Full infrastructure provisioned + app deployed | ✅ |
| Task 2 | App tested — frontend, backend, DB all working | ✅ |
| Task 3 | Submission document prepared | ✅ |
| Task 4 | LinkedIn post published | ✅ |

---

## 💡 Key Learnings

**1. Security group references > CIDR for DB isolation.**
Using `security_groups = [aws_security_group.ec2.id]` on the RDS SG means only EC2 instances in that group can reach port 3306. Not any machine in the subnet range — just that specific group.

**2. RDS requires a DB subnet group spanning 2 AZs.**
Even for single-AZ deployments, AWS requires the subnet group to include subnets in at least 2 availability zones. Always plan for this upfront.

**3. `skip_final_snapshot = true` is required for clean destroy.**
Without this, `terraform destroy` prompts for a final snapshot identifier. Set it to true for learning environments.

**4. Three-tier architecture in practice.**
Public subnet for compute → private subnet for data → security group references to connect them. This is how production applications are actually built.

---

## ⚠️ Issues & Solutions

| Issue | Cause | Fix |
|---|---|---|
| RDS apply failed | Subnet group needs 2 AZs | Added second private subnet in AZ2 |
| App images 404 | Image paths not matching server | Copied assets to Nginx static dir |
| RDS destroy slow | Final snapshot cleanup | Set `skip_final_snapshot = true` |

---

## 🔗 Navigation

← [Assignment 3 — React App on Azure](../Week-10-React-Azure/)
← [Assignment 2 — AWS EC2 in Custom VPC](../Week-10-Terraform-AWS/)
← [Assignment 1 — Azure VM](../Week-10-Terraform-Azure/)

[↑ Back to Main README](../README.md)

---

<div align="center">
<sub>DevOps Micro Internship · Week 10 · Assignment 4 · EpicBook on AWS · Venkatesh Gangavarapu</sub>
</div>
