# Ansible Onboarding

Week 12 — Local Ansible development environment setup with linting, pre-commit hooks, and SSH agent configuration.

---

## Machine Details

| Field            | Value                                         |
|------------------|-----------------------------------------------|
| **User**         | `venky`                                       |
| **Hostname**     | `Venky`                                       |
| **OS**           | Ubuntu 24.04 on WSL2 (Windows)                |
| **Kernel**       | `6.6.87.2-microsoft-standard-WSL2`            |
| **Architecture** | `x86_64`                                      |
| **Python**       | `3.12.3`                                      |
| **Shell**        | `bash`                                        |
| **SSH Key**      | `ED25519` — `gangavarapuvenkatesh3@gmail.com` |

---

## Repository Structure

```
ansible-onboarding/
├── .venv/                      # Local Python virtual environment (not committed)
├── .vscode/
│   └── settings.json           # VS Code workspace settings
├── .editorconfig               # Editor formatting rules
├── .pre-commit-config.yaml     # Pre-commit hooks (yamllint + ansible-lint)
├── ansible.cfg                 # Ansible configuration
├── requirements.txt            # Pinned Python dependencies
└── README.md                   # This file
```

---

## Tool Versions

| Tool              | Version   |
|-------------------|-----------|
| `ansible`         | 13.5.0    |
| `ansible-core`    | 2.20.4    |
| `ansible-lint`    | 26.4.0    |
| `pre-commit`      | 4.5.1     |
| `yamllint`        | 1.38.0    |
| `Jinja2`          | 3.1.6     |
| `PyYAML`          | 6.0.3     |
| `python`          | 3.12.3    |

---

## Setup Instructions

### 1. Clone the repository

```bash
git clone <repo-url>
cd ansible-onboarding
```

### 2. Create and activate the virtual environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Install pre-commit hooks

```bash
pre-commit install
```

### 5. Start SSH agent and add your key

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

---

## Configuration Files

### `ansible.cfg`

```ini
[defaults]
inventory            = inventories/
roles_path           = roles:./.ansible/roles
host_key_checking    = True
retry_files_enabled  = False
interpreter_python   = auto_silent
forks                = 10
timeout              = 30
stdout_callback      = yaml
bin_ansible_callbacks = True

[ssh_connection]
pipelining = True
ssh_args   = -o ControlMaster=auto -o ControlPersist=60s
```

### `.editorconfig`

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true
```

### `.vscode/settings.json`

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "ansible.python.interpreterPath": "${workspaceFolder}/.venv/bin/python",
  "ansibleLint.enabled": true,
  "yaml.validate": true,
  "files.trimTrailingWhitespace": true,
  "editor.formatOnSave": true
}
```

### `.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/adrienverge/yamllint
    rev: v1.35.1
    hooks:
      - id: yamllint
  - repo: https://github.com/ansible/ansible-lint
    rev: v24.6.1
    hooks:
      - id: ansible-lint
```

---

## Verification Checklist

Run the following commands to verify your environment is correctly set up:

### ansible --version

```bash
$ ansible --version
ansible [core 2.20.4]
  config file = None
  configured module search path = ['/home/venky/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = .../.venv/lib/python3.12/site-packages/ansible
  executable location = .../.venv/bin/ansible
  python version = 3.12.3 (main, Mar 3 2026, 12:15:18) [GCC 13.3.0]
  jinja version = 3.1.6
  pyyaml version = 6.0.3
```

### ansible-lint --version

```bash
$ ansible-lint --version
ansible-lint 26.4.0 using ansible-core:2.20.4 ansible-compat:26.3.0 ...
```

### pre-commit run --all-files

```bash
$ pre-commit run --all-files
# Smoke test passes — no playbooks present yet, hooks run cleanly.
yamllint.............................................(no files to check)Skipped
ansible-lint.........................................(no files to check)Skipped
```

### SSH agent running with key loaded

```bash
$ ssh-add -l
256 SHA256:3Va6i00XS5thRMNM6Q7wQ5B9pIpU0CUqxc+oykyRzuY gangavarapuvenkatesh3@gmail.com (ED25519)
```

---

## Checklist

- [x] `.venv/` created locally and activated
- [x] `requirements.txt` generated with pinned versions (`pip freeze`)
- [x] `.vscode/settings.json` configured for Ansible + Python interpreter
- [x] `.editorconfig` set (UTF-8, LF, 2-space indent, trim trailing whitespace)
- [x] `ansible.cfg` configured with SSH pipelining and YAML callback
- [x] `.pre-commit-config.yaml` configured with `yamllint` and `ansible-lint`
- [x] `pre-commit install` run — hooks active on every commit
- [x] `ansible --version` runs without errors
- [x] `ansible-lint --version` runs without errors
- [x] `pre-commit run --all-files` passes (smoke test)
- [x] SSH agent running and ED25519 key loaded (`ssh-add -l` shows key)

---

## VS Code Extensions (Recommended)

| Extension                  | Publisher       |
|----------------------------|-----------------|
| Ansible                    | Red Hat         |
| YAML                       | Red Hat         |
| EditorConfig for VS Code   | EditorConfig    |
| Python                     | Microsoft       |

---

## Notes

- `.venv/` is excluded from version control — run `pip install -r requirements.txt` after cloning.
- `ansible.cfg` uses `inventories/` as the inventory path — create this directory before running playbooks.
- `host_key_checking = True` is intentionally kept enabled for security; disable only in ephemeral lab environments.
- SSH `ControlMaster` + `ControlPersist=60s` reuses connections for faster task execution across plays.
