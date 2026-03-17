```markdown
# Nginx Configuration for React Application

This document explains how Nginx was configured to serve the React application.

```

## Default Nginx Configuration

- File used: /etc/nginx/sites-available/default

## Configuration Used
```nginx
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri /index.html;
    }
}
```

## Test Nginx Configuration
```
sudo nginx -t
```

### Expected result:
- syntax is OK
- test is successful

## Restart Nginx
```bash
sudo systemctl restart nginx
sudo systemctl status nginx
```


