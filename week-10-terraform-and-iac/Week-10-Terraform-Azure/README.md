<div align="center">

# Week 10 — Terraform on Azure

### DevOps Micro Internship · Venkatesh Gangavarapu

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Status](https://img.shields.io/badge/Assignment-Completed-22C55E?style=for-the-badge)

</div>

---

## 🎯 Objective

Automate the deployment of an Azure Virtual Machine using Terraform with proper network configuration and output values — no manual portal clicks.

---

## 🏗️ Infrastructure Built

A complete Azure VM stack provisioned entirely through Terraform:

```
azurerm_resource_group
    └── azurerm_virtual_network  (10.0.0.0/16)
            └── azurerm_subnet   (10.0.1.0/24)
                    └── azurerm_network_interface
                            ├── azurerm_public_ip  (Static)
                            └── azurerm_linux_virtual_machine
                                    (Ubuntu 18.04 · Standard_B1s)
```

---

## 📁 Project Structure

```
Week-10-Terraform-Azure/
├── README.md          ← This file
└── terraform/
    ├── main.tf        ← All 6 Azure resources
    ├── variables.tf   ← Input variables (parameterised)
    ├── outputs.tf     ← Public IP + VM name outputs
    └── provider.tf    ← AzureRM provider + version constraints
```

---

## ⚙️ Resources Defined

| # | Terraform Resource | Azure Resource | Config |
|---|---|---|---|
| 1 | `azurerm_resource_group` | Resource Group | Location: East US |
| 2 | `azurerm_virtual_network` | VNet | Address: 10.0.0.0/16 |
| 3 | `azurerm_subnet` | Subnet | Address: 10.0.1.0/24 |
| 4 | `azurerm_public_ip` | Public IP | Allocation: Static |
| 5 | `azurerm_network_interface` | NIC | Dynamic private IP |
| 6 | `azurerm_linux_virtual_machine` | Ubuntu VM | Standard_B1s · Password auth |

---

## 🚀 Full Terraform Lifecycle

### Prerequisites
```bash
az login                        # Authenticate to Azure
az account show                 # Verify correct subscription
terraform --version             # Confirm Terraform installed
```

### Step 1 — Create Project Directory
```bash
mkdir terraform-azure-vm
cd terraform-azure-vm
```

### Step 2 — Initialise
```bash
terraform init
# Downloads AzureRM provider
# Creates .terraform/ and lock file
```

### Step 3 — Plan
```bash
terraform plan
# Output: Plan: 6 to add, 0 to change, 0 to destroy
# Review every resource BEFORE applying
```

### Step 4 — Apply
```bash
terraform apply
# Type 'yes' to confirm
# Provisions all 6 resources in dependency order
```

### Step 5 — Validate
```bash
# Verify VM is running
az vm list -d --query "[].{Name:name, Status:powerState}"

# Expected output:
# [{ "Name": "terraform-vm", "Status": "VM running" }]

# Get public IP
terraform output
# public_ip_address = "XX.XX.XX.XX"
```

### Step 6 — Destroy
```bash
terraform destroy
# Type 'yes' to confirm
# Destroy complete! Resources: 6 destroyed.
```

---

## 📤 Terraform Outputs

```hcl
public_ip_address  = "XX.XX.XX.XX"     # VM public IP
vm_name            = "terraform-vm"    # VM name
resource_group_name = "terraform-vm-rg"
admin_username     = "adminuser"
```

---

## ✅ Assignment Tasks

| Task | Description | Status |
|---|---|:---:|
| Task 1 | Complete the lab — init, plan, apply, destroy | ✅ |
| Task 2 | Validate VM via `az vm list -d` | ✅ |
| Task 3 | Submit screenshots + reflection | ✅ |

---

## 💡 Key Learnings

**1. Terraform handles dependency ordering automatically.**
I didn't manually specify that the VM needs the NIC → subnet → VNet.
Terraform reads the HCL references and builds the correct graph automatically.
That's declarative IaC — describe *what* you want, not *how* to build it.

**2. `terraform plan` is non-negotiable.**
Seeing `6 to add, 0 to change, 0 to destroy` before touching live Azure resources
is what separates controlled IaC from ad-hoc scripting.

**3. Same IaC thinking — any cloud.**
Coming from Week 9 (Agentic AI on AWS with Claude Code), this week confirmed
the mental model transfers. Different provider, same discipline.

---

## ⚠️ Issues Faced & Solutions

| Issue | Root Cause | Solution |
|---|---|---|
| `terraform init` failed | Azure CLI not authenticated | Run `az login` first, verify with `az account show` |
| `az vm list` returned `[]` | Azure API propagation delay | Wait 30 seconds, re-run the command |
| `terraform destroy` failed on public IP | Azure eventual consistency timing | Re-run `terraform destroy` — resolved on second attempt |

---

## 🔗 Navigation

← [Week 09 — Agentic AI DevOps with Claude Code](../Week-09-Agentic-AI-Claude-Code/)
→ Week 11 — Coming Soon

[↑ Back to Main README](../README.md)

---

<div align="center">
<sub>DevOps Micro Internship · Week 10 · Terraform on Azure · Venkatesh Gangavarapu</sub>
</div>
