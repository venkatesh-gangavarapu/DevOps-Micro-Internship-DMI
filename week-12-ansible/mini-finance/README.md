# Mini Finance — Terraform + Ansible Deployment

## Structure
mini-finance/
├── terraform/          # Azure VM provisioning
│   ├── providers.tf
│   └── main.tf
├── ansible/            # Config + deploy
│   ├── inventory.ini
│   └── site.yml
└── README.md

## Deploy Infrastructure
cd terraform/
terraform init && terraform apply

## Deploy Application
cd ansible/
source ../../.venv/bin/activate
ansible-playbook -i inventory.ini site.yml

## Verify
Open browser: http://<public_ip>

## Play Summary
| Play | Target    | Job                              |
|------|-----------|----------------------------------|
| 1    | [web]     | Install nginx + git              |
| 2    | [web]     | Clone repo + deploy to html root |
| 3    | localhost | Assert HTTP 200                  |
