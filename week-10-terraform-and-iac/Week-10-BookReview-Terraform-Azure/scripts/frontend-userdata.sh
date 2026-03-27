#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

PUBLIC_LB_IP="${public_lb_ip}"
INTERNAL_LB_IP="${private_lb_ip}"

APP_DIR="/home/ubuntu/book-review-app"
FRONTEND_DIR="$APP_DIR/frontend"
NGINX_CONF="/etc/nginx/sites-available/book-review"

exec > >(tee /var/log/frontend-user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "========================================"
echo "Updating system..."
echo "========================================"
apt update && apt upgrade -y

echo "========================================"
echo "Installing Node.js, Nginx, and Git..."
echo "========================================"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs nginx git

echo "========================================"
echo "Cloning or updating frontend repo..."
echo "========================================"
if [ -d "$APP_DIR" ]; then
  cd "$APP_DIR"
  git pull
else
  git clone https://github.com/pravinmishraaws/book-review-app.git "$APP_DIR"
fi

chown -R ubuntu:ubuntu "$APP_DIR"

cd "$FRONTEND_DIR"

echo "========================================"
echo "Installing frontend dependencies..."
echo "========================================"
sudo -u ubuntu npm install

echo "========================================"
echo "Creating .env.local..."
echo "========================================"
cat > .env.local <<EOF
NEXT_PUBLIC_API_URL=http://${public_lb_ip}
EOF

chown ubuntu:ubuntu .env.local

echo "========================================"
echo "Building frontend..."
echo "========================================"
sudo -u ubuntu npm run build

echo "========================================"
echo "Installing PM2..."
echo "========================================"
npm install -g pm2

echo "========================================"
echo "Restarting frontend with PM2..."
echo "========================================"
sudo -u ubuntu pm2 delete frontend || true
sudo -u ubuntu pm2 start npm --name frontend -- start
sudo -u ubuntu pm2 save

echo "========================================"
echo "Configuring PM2 startup..."
echo "========================================"
env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu || true

echo "========================================"
echo "Creating Nginx config..."
echo "========================================"
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name _;

    location /api/ {
        proxy_pass http://${private_lb_ip}:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header Origin            http://${public_lb_ip};
        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade           \$http_upgrade;
        proxy_set_header Connection        "upgrade";
        proxy_set_header Host              \$host;
        proxy_cache_bypass                 \$http_upgrade;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }
}
EOF

echo "========================================"
echo "Enabling Nginx site..."
echo "========================================"
ln -sf /etc/nginx/sites-available/book-review /etc/nginx/sites-enabled/book-review
rm -f /etc/nginx/sites-enabled/default

echo "========================================"
echo "Testing Nginx config..."
echo "========================================"
nginx -t

echo "========================================"
echo "Reloading Nginx..."
echo "========================================"
systemctl enable nginx
systemctl restart nginx

echo "========================================"
echo "Deployment complete"
echo "========================================"
sudo -u ubuntu pm2 status
systemctl status nginx --no-pager
