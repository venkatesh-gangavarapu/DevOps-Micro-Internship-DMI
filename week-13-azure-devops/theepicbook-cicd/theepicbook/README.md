# EpicBook App Deployment Pipeline (Stage 2)

This repository is the second part of a dual-pipeline delivery flow for EpicBook.

- Stage 1 (infra pipeline): provisions Azure infrastructure (VM, networking, MySQL) and exports runtime outputs.
- Stage 2 (this repo): deploys and configures the application on the VM with Ansible, using outputs and secrets injected at runtime.

## Why This Repo Exists

`app-epicbook` handles application configuration and deployment only. It intentionally does not own infrastructure creation, and it does not hardcode environment-specific runtime values.

## Dual-Pipeline Architecture

1. Infra pipeline runs from `infra-epicbook` and creates cloud resources.
2. Infra pipeline publishes/exports runtime outputs needed by app deployment:
   - VM public IP
   - MySQL host/FQDN
3. This app pipeline is triggered by the infra pipeline completion (`resources.pipelines` trigger in `azure-pipelines.yml`).
4. This pipeline downloads infra outputs, loads them into pipeline variables, and generates `inventory.ini` dynamically.
5. Ansible applies:
   - base OS and runtime setup (`common` role)
   - reverse proxy setup (`nginx` role)
   - EpicBook app deployment and DB initialization (`epicbook` role)

## Why Web IP and Password Are Not Defined Here

### Web IP is intentionally not hardcoded

The web server IP is created by Terraform in Stage 1 and can differ per environment or after re-provisioning. Hardcoding it in this repository would make deployments brittle and environment-coupled.

Instead, this pipeline injects it at runtime and writes it into a generated inventory:

- Pipeline script reads infra output values.
- `inventory.ini` is generated on the fly with the injected host value.

### SSH password is intentionally not used

This pipeline deploys using SSH key authentication (`id_rsa` secure file), not password authentication.

Security reasons:

- avoids storing or exposing SSH passwords in source control
- reduces credential sprawl across environments
- aligns with hardened VM access patterns

Operationally, this also matches the hardening done in Ansible (`common` role), where password authentication is disabled in SSH config.

## Why DB Host and DB Password Are Not Hardcoded

### DB host is environment output

`db_host` comes from infrastructure outputs because the database endpoint is created by Terraform and is environment-specific.

### DB password is secret material

`db_password` is secret data and must never be committed to Git. It should come from secure secret stores (Azure DevOps variable groups, Key Vault, or equivalent), then be injected into the pipeline at runtime.

## Runtime Variable and Secret Contract

This pipeline expects:

1. Infra outputs available at runtime:
   - `vmPublicIp` (or equivalent value mapped to this name)
   - `db_host`
2. Secret variable group:
   - `epicbook-secrets` with `db_password`
3. Secure file:
   - `id_rsa` private key for SSH

Note:

- `group_vars/web/main.yml` stores stable non-secret defaults (app path, db name, db user, app port).
- dynamic values and secrets are passed through pipeline variables and `-e` extra vars at playbook runtime.

## Repository Layout

```text
app-epicbook/
  azure-pipelines.yml          # Stage-2 deployment pipeline
  site.yml                     # Main Ansible playbook
  inventory.ini                # Placeholder; overwritten dynamically in pipeline
  group_vars/web/main.yml      # Static non-secret defaults
  roles/
    common/                    # Base OS/runtime preparation
    nginx/                     # Reverse proxy setup
    epicbook/                  # App deploy, DB schema/seed, PM2 process management
```

## Deployment Flow in This Repo

1. Checkout app deployment repo.
2. Download infra outputs artifact.
3. Load `vmPublicIp` and `db_host` into pipeline variables.
4. Download SSH private key (`id_rsa`) as secure file.
5. Install Ansible and dependencies.
6. Generate runtime `inventory.ini` with injected host.
7. Validate SSH/Ansible connectivity.
8. Run `ansible-playbook site.yml` with:
   - `db_host` (injected from infra)
   - `db_password` (injected secret)
9. Verify app availability via HTTP on the injected VM IP.

## Local Testing (Optional)

If you need to run Ansible manually for debugging, do not hardcode secrets in files.

Example:

```bash
ansible-playbook site.yml -i inventory.ini \
  -e "db_host=<injected-db-host>" \
  -e "db_password=<injected-secret>"
```

## Security and Compliance Notes

- Do not commit live `inventory.ini` with real IPs.
- Keep `db_password` only in secret management.
- Prefer SSH key auth and keep private keys in Azure DevOps secure files.

## Common Pitfalls

- Infra output naming mismatch (`public_ip` vs `vmPublicIp`) can break Stage 2 variable loading.
- Missing `db_password` in `epicbook-secrets` causes app config and DB seeding failures.
- Missing or incorrect `id_rsa` secure file causes SSH connection failures.

## Summary

This project is designed so environment-specific values and secrets are injected at deployment time, not stored in code. That is why web IP, SSH password, DB host, and DB password are not defined as hardcoded values in this repository.