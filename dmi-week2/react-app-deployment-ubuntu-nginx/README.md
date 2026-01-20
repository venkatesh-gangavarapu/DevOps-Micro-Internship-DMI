# React App Deployment on Ubuntu using Nginx

This repository documents the complete process of deploying a React application
on an Ubuntu Virtual Machine using **Nginx** as a web server.

The objective is to gain hands-on experience with Linux, application builds,
web server configuration, and public deployment.

---

## 📌 Project Details
- OS: Ubuntu Linux
- Application: React.js
- Web Server: Nginx
- Package Manager: npm
- Deployment Type: Static build served via Nginx

---

## 🛠️ Steps Covered

### 1️⃣ Software Installation
- Installed Node.js and npm
- Installed, started, and enabled Nginx

📂 Documentation: `installation/install-node-nginx.md`

---

### 2️⃣ React Application Setup
- Cloned the React app repository
- Modified `App.js` with:
  - Full Name
  - Deployment Date

📂 Documentation: `application-modification/appjs-update.md`

---

### 3️⃣ Build & Deployment
- Installed dependencies using `npm install`
- Created production build using `npm run build`
- Deployed build files to `/var/www/html`

📂 Documentation: `build-and-deploy/react-build-deployment.md`

---

### 4️⃣ Nginx Configuration
- Configured Nginx to serve React build
- Restarted Nginx service
- Verified service status

📂 Documentation: `nginx/nginx-config.md`

---

### 5️⃣ Verification
- Accessed application using VM public IP
- Verified React app loads successfully in browser

📂 Proof: `Documented`

---

## 📸 Proof of Execution
All documented for each step are available in the `document/` folder.

---

## 🎯 Learning Outcomes
- Linux server setup and package management
- React build lifecycle understanding
- Nginx configuration and service control
- Real-world application deployment experience

📌 *This work is part of DevOps Micro-Internship (DMI) by Pravin Mishra.*

