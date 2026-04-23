# Week 14 — Static Website Docker Image
# Base: nginx:alpine (~25MB — lightweight production image)
# Serves the Azure-Static-Website via Nginx on port 80

FROM nginx:alpine

# Remove default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy static site files into nginx web root
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# nginx runs by default — no CMD override needed
