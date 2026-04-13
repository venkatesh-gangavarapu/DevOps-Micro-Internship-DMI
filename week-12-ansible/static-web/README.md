# Static Website Deployment — Ansible Multi-Play Playbook

## Structure
static-web/
├── inventory.ini          # web, app, db groups
├── site.yml               # 3-play deployment playbook
├── files/
│   └── index.html         # static content (from Azure-Static-Website repo)
└── README.md

## How to Run
source ../.venv/bin/activate
ansible-playbook -i inventory.ini site.yml

## Verify
curl http://<web_ip>
# or open in browser

## Play Summary
| Play | Target    | Job                        |
|------|-----------|----------------------------|
| 1    | [web]     | Install + start nginx      |
| 2    | [web]     | Deploy index.html          |
| 3    | localhost | Assert HTTP 200 on each IP |
