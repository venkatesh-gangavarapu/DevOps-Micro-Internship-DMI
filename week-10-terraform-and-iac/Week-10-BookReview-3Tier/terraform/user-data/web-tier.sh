#!/bin/bash
# Web Tier Bootstrap — Next.js + Nginx
apt-get update -y && apt-get upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs git nginx

# Clone and build the Book Review frontend
git clone https://github.com/pravinmishraaws/book-review-app /app/frontend
cd /app/frontend
npm install
npm run build
npm start &

# Nginx reverse proxy — port 80 → Next.js :3000
cat > /etc/nginx/sites-available/default <<'EOF'
server {
  listen 80;
  location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
EOF

nginx -t && systemctl reload nginx
systemctl enable nginx
