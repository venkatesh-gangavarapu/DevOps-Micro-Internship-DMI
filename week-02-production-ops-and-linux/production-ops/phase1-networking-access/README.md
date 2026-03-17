# Production OPS – Phase 1: Networking & Access Checks

This repository documents **Phase 1 of a Production Maintenance Drill**
focused on **Networking & Access validation**.

The goal is to verify that a production server is:
- Reachable
- Properly networked
- Securely exposing only required services

This phase reflects **real on-call / OPS-first thinking**.

---

## 📌 Scope of Phase 1

The following production checks are covered:

- Network interfaces and IP validation
- Default gateway and routing
- DNS resolution
- External connectivity
- Listening ports and owning processes
- Firewall status

Each check includes:
- Command executed
- Screenshot evidence
- What the output means
- Why it matters in production

---


## 🔐 Key Production Findings

- Network interface is UP and assigned a valid IP
- Default route and DNS resolution are functional
- External connectivity is confirmed
- Only expected ports are exposed:
  - HTTP (80) via Nginx
  - SSH (22)
- No unexpected open ports detected

---

## 🎯 Why This Matters

These checks are the **first step of any real on-call investigation**.
If Phase 1 fails, higher-level debugging is meaningless.

---

📌 *This work is part of DevOps Micro-Internship (DMI) by Pravin Mishra.*

