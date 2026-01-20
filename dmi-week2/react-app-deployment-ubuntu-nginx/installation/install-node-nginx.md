# Install Node.js, npm, and Nginx

## Install Node.js & npm
```bash
sudo apt update
sudo apt install -y nodejs npm
node -v && npm -v
```

## Install and Start Nginx
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Verification of Nginx
```bash
sudo systemctl status nginx
```

