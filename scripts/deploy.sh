#!/bin/bash
# Basic deploy helper for LiveWire Portal
set -e

echo "Cloning or updating repo..."
if [ -d "livewire-portal" ]; then
    cd livewire-portal && git pull
else
    git clone https://github.com/mike0615/livewire-portal.git
    cd livewire-portal
fi

echo "Copying configs..."
sudo cp -r configs/apache/* /etc/httpd/conf.d/ 2>/dev/null || true
sudo cp configs/prosody/prosody.cfg.lua.example /etc/prosody/prosody.cfg.lua

echo "Restarting services..."
sudo systemctl restart httpd prosody haproxy keepalived

echo "Done. Check logs: journalctl -u httpd -u prosody"

echo "Next: install WordPress, plugins, and theme manually or via WP-CLI."