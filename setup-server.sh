#!/usr/bin/env bash
set -e

echo "=== Boma multi-app server bootstrap starting ==="

# ---- sanity check ----
if [[ $EUID -ne 0 ]]; then
  echo "Run this script with sudo"
  exit 1
fi

APP_USER="clawdbot"
NODE_VERSION="20.x"

# ---- base system ----
echo "[1/9] Updating system"
apt update && apt upgrade -y

apt install -y \
  curl git ufw ca-certificates gnupg \
  build-essential software-properties-common

# ---- firewall ----
echo "[2/9] Configuring UFW"
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

# ---- Node.js ----
echo "[3/9] Installing Node.js LTS"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
apt install -y nodejs

npm install -g pm2

# ---- PM2 startup ----
echo "[4/9] Enabling PM2 startup"
su - "$APP_USER" -c "pm2 startup systemd -u $APP_USER --hp /home/$APP_USER" >/dev/null

# ---- Nginx ----
echo "[5/9] Installing Nginx"
apt install -y nginx
systemctl enable nginx
systemctl start nginx

# ---- Certbot ----
echo "[6/9] Installing Certbot"
apt install -y certbot python3-certbot-nginx

# ---- Netdata ----
echo "[7/9] Installing Netdata (monitoring GUI)"
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait

# Secure Netdata (local only, proxied later if desired)
sed -i 's/^# bind socket to IP =.*/bind socket to IP = 127.0.0.1/' /etc/netdata/netdata.conf
systemctl restart netdata

# ---- GoAccess ----
echo "[8/9] Installing GoAccess"
apt install -y goaccess

mkdir -p /var/www/html
cat >/etc/goaccess/goaccess.conf <<EOF
time-format %H:%M:%S
date-format %d/%b/%Y
log-format COMBINED
EOF

# ---- Fail2ban ----
echo "[9/9] Installing Fail2ban"
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

echo
echo "=== INSTALL COMPLETE ==="
echo
echo "What you now have:"
echo "- Nginx on :80/:443"
echo "- Node.js + PM2 for multiple apps"
echo "- Netdata GUI (proxied, localhost only)"
echo "- GoAccess ready for Nginx log UI"
echo "- Fail2ban active"
echo
echo "Next steps:"
echo "1. Deploy apps on ports (3000, 3001, ...)"
echo "2. Create Nginx site files per app"
echo "3. Run: certbot --nginx"
echo "4. (Optional) Proxy Netdata behind HTTPS"
echo
echo "You're now running a serious server."
