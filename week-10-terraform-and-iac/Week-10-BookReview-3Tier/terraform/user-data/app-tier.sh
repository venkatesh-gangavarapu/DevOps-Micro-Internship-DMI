#!/bin/bash
# App Tier Bootstrap — Node.js backend
apt-get update -y && apt-get upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs git mysql-client

# Clone and start the Book Review backend
git clone https://github.com/pravinmishraaws/book-review-app /app/backend
cd /app/backend
npm install

# .env will be set via Terraform or SSM — placeholder
cat > .env <<'EOF'
DB_HOST=REPLACE_WITH_RDS_ENDPOINT
DB_USER=admin
DB_PASSWORD=SecurePass1234!
DB_NAME=bookreview
PORT=3001
EOF

npm start &
