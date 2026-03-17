# ─────────────────────────────────────────────────────────────────────────────
# Remote State Backend (S3)
#
# INSTRUCTIONS — two-phase setup:
#
#   Phase 1 — First-time bootstrap (backend commented out):
#     1. Leave this block commented out.
#     2. Run: terraform init
#     3. Run: terraform apply
#        This creates the S3 bucket and other resources.
#        Note the bucket name from the outputs.
#
#   Phase 2 — Migrate state to S3:
#     1. Create a separate S3 bucket for Terraform state (if not already done).
#     2. Fill in `bucket`, `key`, and `region` below.
#     3. Uncomment the terraform { backend "s3" { ... } } block.
#     4. Run: terraform init -migrate-state
#        Terraform will copy the local state to S3.
# ─────────────────────────────────────────────────────────────────────────────

# terraform {
#   backend "s3" {
#     bucket  = "YOUR-TERRAFORM-STATE-BUCKET"   # e.g. "venkateshgangavarapu-tf-state"
#     key     = "portfolio/terraform.tfstate"
#     region  = "ap-south-1"
#     encrypt = true
#   }
# }
