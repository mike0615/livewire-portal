#!/bin/bash
# Hardened deploy helper for LiveWire Portal
# Fails fast on any error. Run as root or with sudo.
set -euo pipefail

REPO_DIR="livewire-portal"
BRANCH="main"

echo "[1/5] Cloning or updating repo..."
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git fetch origin
    git checkout "$BRANCH"
    git pull --ff-only origin "$BRANCH"
else
    git clone https://github.com/mike0615/livewire-portal.git "$REPO_DIR"
    cd "$REPO_DIR"
    git checkout "$BRANCH"
fi

echo "[2/5] Copying Apache configs..."
sudo cp -r configs/apache/* /etc/httpd/conf.d/
sudo apachectl configtest

echo "[3/5] Copying Prosody config..."
sudo cp configs/prosody/prosody.cfg.lua.example /etc/prosody/prosody.cfg.lua

echo "[4/5] Copying HAProxy + Keepalived (review secrets first!)..."
sudo cp configs/haproxy/haproxy.cfg.example /etc/haproxy/haproxy.cfg
sudo cp configs/keepalived/keepalived.conf.example /etc/keepalived/keepalived.conf

echo "[5/5] Restarting services..."
sudo systemctl restart httpd
sudo systemctl restart prosody
sudo systemctl restart haproxy
sudo systemctl restart keepalived

echo "Deploy complete."
echo "Next: install/activate WordPress, child theme, and plugins via WP-CLI."
echo "Smoke test: SSO -> dashboard -> chat -> mail -> files."