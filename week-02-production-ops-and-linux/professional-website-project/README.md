# Deploy a Professional Website – Confidence Project

This repository documents **Assignment 4: Confidence Project**, where a
professional static website is deployed on an **Ubuntu VM using Nginx**
following **production-like DevOps practices**.

The focus is not just deployment, but **operational confidence**.

---

## 🎯 Project Objective

- Deploy a professional website using Nginx
- Add deployment ownership proof (anti-copy)
- Validate the system like a real production service
- Perform OPS-style checks instead of assuming success

---

## 📂 Assignment Structure
- Document stored in `document/` folder

### Task 0 – Pre-flight Check
- Hostname, OS, Nginx version
- Nginx service health validation

### Task 1 – Website Source Code
- Clone or download website source
- Understand structure before deployment

### Task 2 – Ownership Proof (Anti-Copy)
- Footer updated with cohort, name, group, week, and date
- Proof visible in browser UI

### Task 3 – Deploy Website via Nginx
- Backup existing content
- Deploy website to `/var/www/html`
- Set permissions
- Restart and validate Nginx

### Task 5 – Mini “Real DevOps” OPS Check
- External availability check
- Configuration safety (`nginx -t`)
- Service health
- Stability commitment (24 hours)

---

## 🌐 Live Website
- http://<YOUR_PUBLIC_IP>
