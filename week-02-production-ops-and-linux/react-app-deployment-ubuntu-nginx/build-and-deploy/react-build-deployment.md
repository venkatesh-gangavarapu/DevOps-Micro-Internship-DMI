# React Application Build & Deployment

This document covers building the React application and deploying it to Nginx’s
web root directory.

---

## Install Dependencies

```bash
cd my-react-app
npm install
```

## Build React Application
```bash
npm run build
```
- Build Completed successfully.
- Static files generated inside `build` directory

## Deploy Build to Nginx Web Root
```bash
sudo rm -rf /var/www/html/*
sudo cp -r build/* /var/www/html/
```
### Verification
```bash
ls /var/www/html
```



