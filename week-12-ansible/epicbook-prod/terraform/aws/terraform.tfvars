# Override defaults here — do NOT commit secrets to version control.
# Copy this file to terraform.tfvars.local for sensitive values.

aws_region          = "us-east-1"
project_name        = "epicbook"
instance_type       = "t3.micro"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
