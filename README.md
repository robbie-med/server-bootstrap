# Server Bootstrap Script

One-shot setup script for a fresh **Ubuntu 24.04 LTS** server that supports running **multiple web applications** on different ports, all securely exposed via **HTTPS**, with **GUI monitoring** for traffic, ports, errors, and suspicious activity.

This repository is intended as a reusable baseline for any self-hosted server.

---

## What This Sets Up

After running the script, the server will have:

- **Nginx**
  - Central HTTPS entry point (ports 80 / 443)
  - Reverse proxy to multiple internal apps

- **Node.js (LTS)**
  - Modern JavaScript runtime

- **PM2**
  - Process manager for running multiple apps on different ports
  - Auto-restart, logging, and resource monitoring

- **Certbot (Let’s Encrypt)**
  - Automated TLS certificates

- **Netdata**
  - Web-based GUI for:
    - Active TCP connections
    - Port usage
    - Network traffic
    - CPU and memory usage
    - Nginx request rates
    - Anomalies and spikes

- **GoAccess**
  - Web-based Nginx access log analyzer
  - Per-IP, per-path, and per-status visibility

- **Fail2ban**
  - Automatic banning of abusive IPs

- **UFW Firewall**
  - Only SSH, HTTP, and HTTPS exposed

---

## Architecture Overview

```
Internet
   |
   v
Nginx (HTTPS :443)
   |
   +--> App A (localhost:3000)
   +--> App B (localhost:3001)
   +--> App C (localhost:3002)
```

Applications bind to `localhost` only and are never exposed directly to the internet.

---

## Requirements

- Fresh **Ubuntu 24.04 LTS**
- Root or sudo access
- A VPS or bare-metal server

---

## Usage

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/server-bootstrap.git
cd server-bootstrap
```

### 2. Run the setup script
```bash
chmod +x setup-server.sh
sudo ./setup-server.sh
```

The script is safe to re-run and will not remove user data.

---

## Running Applications

Start applications on arbitrary ports using PM2:

```bash
pm2 start app.js --name app1 -- --port 3000
pm2 start app.js --name app2 -- --port 3001
pm2 save
```

---

## Nginx Reverse Proxy Example

Create one Nginx site per application:

```bash
sudo nano /etc/nginx/sites-available/app1
```

```nginx
server {
    listen 443 ssl;
    server_name app1.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```

Enable and reload:

```bash
sudo ln -s /etc/nginx/sites-available/app1 /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## Enabling HTTPS

```bash
sudo certbot --nginx
```

Certificates are renewed automatically.

---

## Monitoring

### Netdata
```
http://SERVER_IP:19999
```

Provides real-time visibility into:
- Network connections
- Port usage
- Traffic patterns
- Errors and spikes

(Recommended to proxy behind Nginx and HTTPS.)

---

### GoAccess

Generate a real-time HTML report:

```bash
sudo goaccess /var/log/nginx/access.log \
  --log-format=COMBINED \
  --real-time-html \
  -o /var/www/html/report.html
```

Access at:
```
https://yourdomain.com/report.html
```

---

## Security Notes

- Applications listen on `localhost` only
- Public ports limited to 22, 80, and 443
- Fail2ban runs automatically
- Netdata is bound to localhost by default
- Rotate all secrets and API keys after deployment

---

## Customization

You may customize:
- Node.js version
- Firewall rules
- Monitoring exposure
- App runtime (Node, Python, etc.)

---

## License

MIT License
