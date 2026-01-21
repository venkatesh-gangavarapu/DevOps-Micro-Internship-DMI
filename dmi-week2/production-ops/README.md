# Production OPS – Week 2 (DevOps Micro Internship)

This directory contains a **complete Production Operations (OPS) Maintenance Drill**
performed as part of **Week 2** of the DevOps Micro Internship (DMI).

The goal of this exercise is to move beyond “deployment success” and validate
**production readiness**, **observability**, **reliability**, and **incident recovery**
using real on-call style checks.

---

## 📂 Directory Structure

```text
production-ops/
├── document/
├── phase1-networking-access/
├── phase2-service-health/
├── phase3-logs-request-trace/
├── phase4-system-resource-health/
├── phase5-config-content-integrity/
└── phase6-incident-simulation-recovery/

```

## What Each Phase Covers

### Phase 1 – Networking & Access
- Network interfaces, routing, DNS
- Port exposure (22, 80)
- Firewall status
- External reachability checks

### Phase 2 – Service Health (systemd style)
- Service status and boot reliability
- Config validation before restart
- PID and port ownership
- Safe restart drill

### Phase 3 – Logs & Request Trace
- Traffic generation using curl
- Access log verification
- Error log analysis
- systemd journal review

### Phase 4 – System Resource Health
- Load and uptime
- Memory usage
- Disk utilization
- /var growth and capacity risk analysis

### Phase 5 – Configuration & Content Integrity
- Correct build verification
- Web root validation
- SPA routing confirmation
- Release safety checks

### Phase 6 – Incident Simulation & Recovery
- Bad Nginx config simulation
- Missing content simulation
- Broken vs recovered proof
- Root cause, fix, and prevention
- On-call style reasoning

### 📸 Evidence
- Document stored in `document/` folder.
- Includes both **broken** and **recovered** states


## 🎯 Why This Matters

- In real production environments:
- “It works” is not enough
- Logs matter more than assumptions
- Restarts are risky without validation
- Recovery skill matters more than uptime history

This drill demonstrates how a DevOps/OPS engineer thinks under pressure.

📌 This work is part of DevOps Micro Internship (DMI) by Pravin Mishra.
