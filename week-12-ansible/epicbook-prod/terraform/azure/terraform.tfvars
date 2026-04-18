# Override defaults here — do NOT commit secrets to version control.
# Copy this file to terraform.tfvars.local for sensitive values.

location            = "Central India"
project_name        = "epicbook"
vm_size             = "Standard_D2s_v3"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
admin_username      = "azureuser"
