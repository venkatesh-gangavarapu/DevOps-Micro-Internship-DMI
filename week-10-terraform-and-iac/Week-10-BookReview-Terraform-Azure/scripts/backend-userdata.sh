#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

DB_HOST="${db_host}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
DB_NAME="${db_name}"
ALLOWED_ORIGINS="${public_lb_ip}"

exec > >(tee /var/log/backend-user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "========================================"
echo "Updating system..."
echo "========================================"
apt update && apt upgrade -y

echo "========================================"
echo "Installing Node.js and dependencies..."
echo "========================================"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs mysql-client nginx git

echo "========================================"
echo "Cloning project..."
echo "========================================"
if [ -d "/home/ubuntu/book-review-app" ]; then
  cd /home/ubuntu/book-review-app
  git pull
else
  git clone https://github.com/pravinmishraaws/book-review-app.git /home/ubuntu/book-review-app
fi

chown -R ubuntu:ubuntu /home/ubuntu/book-review-app

cd /home/ubuntu/book-review-app/backend

echo "========================================"
echo "Installing backend dependencies..."
echo "========================================"
sudo -u ubuntu npm install

echo "========================================"
echo "Creating .env file..."
echo "========================================"
cat > .env <<EOF
# Database
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
DB_DIALECT=mysql

# App port
PORT=3001

# Auth
JWT_SECRET=mysecret

# CORS
ALLOWED_ORIGINS=http://${public_lb_ip}
EOF

chown ubuntu:ubuntu .env

echo "========================================"
echo "Installing PM2..."
echo "========================================"
npm install -g pm2

echo "========================================"
echo "Restarting backend with PM2..."
echo "========================================"
sudo -u ubuntu pm2 delete bk-backend || true
sudo -u ubuntu pm2 start src/server.js --name bk-backend
sudo -u ubuntu pm2 save

echo "========================================"
echo "Setting up PM2 startup..."
echo "========================================"
env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu || true

echo "========================================"
echo "Deployment complete"
echo "========================================"
sudo -u ubuntu pm2 status
