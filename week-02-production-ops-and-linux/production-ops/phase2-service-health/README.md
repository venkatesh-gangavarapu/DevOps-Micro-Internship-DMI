# Production OPS – Phase 2: Service Health & Process Validation

This repository documents **Phase 2 of a Production Maintenance Drill**,
focused on validating that services are **healthy, restart-safe,
and manageable using systemd**.

This phase answers a critical production question:
> “Can this service be safely operated during deploys and incidents?”

---

## 📌 Scope of Phase 2

The following production checks are covered:

- Service status via systemd
- Service enablement on boot
- Configuration validation before restart
- Master and worker process verification
- Port ownership confirmation
- Safe restart drill (deploy simulation)
- Risk and rollback reasoning

Each check includes:
- Command executed
- Screenshot evidence
- Meaning of the output
- Production impact

---



### 📸 Evidence
- Document stored in `documents/`


---

## 🔐 Key Production Findings

- Nginx is active and managed by systemd
- Service is enabled on boot
- Configuration is valid before restart
- Master and worker processes are running
- Port 80 is owned by Nginx
- Restart drill completed without downtime

---

## 🎯 Why This Phase Matters

Most production outages happen during restarts or deploys.
This phase ensures:
- Restarts are predictable
- Failures are detectable early
- Rollbacks are possible

---

📌 *This work is part of DevOps Micro-Internship (DMI) by Pravin Mishra.*

