# Production OPS – Phase 3: Logs & Request Trace

This repository documents **Phase 3 of a Production Maintenance Drill**,
focused on **log analysis and request traceability**.

In real DevOps work, a service being “up” is not enough.
Logs are required to confirm:
- Clean traffic flow
- Absence of hidden errors
- Service stability during restarts

---

## 📌 Scope of Phase 3

This phase covers:

- Generating real traffic to update logs
- Validating Nginx access logs
- Checking error logs for failures or misconfigurations
- Reviewing systemd journal logs for service-level issues
- Interpreting log severity correctly (notice vs error)

Each check includes:
- Command executed
- Screenshot evidence
- What the output means
- Why it matters in production

---


### 📸 Evidence
- Document stored in `document/`

### 🧠 Reflection
- OPS learnings documented in `reflection/ops-reflection.md`

---

## 🔎 Key Production Findings

- Curl-generated requests are visible in access logs
- No `[error]` or `[warn]` entries observed
- Only a normal Nginx `[notice]` related to socket inheritance was present
- No service-level failures detected in systemd journal

---

## 🎯 Why This Phase Matters

Most production issues are discovered through logs, not dashboards.
This phase validates that the system is:
- Observable
- Traceable
- Operationally transparent

---

📌 *This work is part of DevOps Micro-Internship (DMI) by Pravin Mishra.*

