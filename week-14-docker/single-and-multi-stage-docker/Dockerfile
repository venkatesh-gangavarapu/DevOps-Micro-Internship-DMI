# ─────────────────────────────────────────────
# Stage 1 — Builder
# Build the React app using Node.js
# This entire stage is DISCARDED after build
# Node.js, npm, node_modules never reach prod
# ─────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency files FIRST
# Maximises Docker layer cache:
# npm install only re-runs when package.json changes
# not every time a source file changes
COPY package.json package-lock.json ./

# Install dependencies cleanly
RUN npm ci --silent

# Copy remaining source files
COPY . .

# Build React app — produces the build/ directory
RUN npm run build

# ─────────────────────────────────────────────
# Stage 2 — Runtime
# Serve compiled static files with Nginx
# Only build/ output is carried forward
# Final image: ~25MB vs ~1.2GB single-stage
# ─────────────────────────────────────────────
FROM nginx:alpine AS runtime

# Remove default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy ONLY the compiled output from Stage 1
# Everything else (Node.js, npm, source) is left behind
COPY --from=builder /app/build /usr/share/nginx/html

# Nginx config for React SPA
# try_files handles client-side routing (React Router)
# error_page 404 catches direct URL access and refreshes
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    location / {\n\
        try_files $uri /index.html;\n\
    }\n\
\n\
    error_page 404 /index.html;\n\
\n\
    # Cache static assets\n\
    location ~* \\.(?:js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

# Health check — confirms nginx is serving correctly
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1
