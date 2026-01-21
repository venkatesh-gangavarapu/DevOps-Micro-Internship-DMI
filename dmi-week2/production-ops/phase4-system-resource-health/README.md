# Production OPS – Phase 4: System Resource Health (Capacity Red Flags)

This repository documents **Phase 4 of a Production Maintenance Drill**,
focused on identifying **capacity risks** before they cause outages.

This phase answers a core production question:
> “Can this host handle traffic, or is it close to failure?”

---

## 📌 Scope of Phase 4

The following system-level checks are covered:

- Load average and uptime
- Memory usage and swap visibility
- Disk usage across filesystems
- Identification of largest disk consumers under `/var`
- Capacity risk assessment and failure impact

Each check includes:
- Command executed
- Screenshot evidence
- What the output means
- Why it matters in production

---

### 📸 Evidence
- Document stored in `document/` folder

### 🧠 Reflection
- Capacity and OPS learnings documented in `reflection/ops-reflection.md`

---

## 🚨 Key Capacity Findings

- CPU load is within safe limits
- Memory usage is stable with sufficient available memory
- Disk usage is the highest long-term risk
- `/var` directory growth (logs) must be monitored continuously

---

## 🎯 Why This Phase Matters

Most production outages are caused by **resource exhaustion**, not bugs.
Early detection of capacity risks prevents downtime and data loss.

---

📌 *This work is part of DevOps Micro-Internship (DMI) by Pravin Mishra.*

