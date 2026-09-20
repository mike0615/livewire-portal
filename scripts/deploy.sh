#!/bin/bash
# Hardened, secret-safe deploy helper for LiveWire Portal.
# Fails fast. Run as root or with sudo for service steps.
#
# Working FQDNs: portal.acc.local / xmpp.acc.local / mail.acc.local
# Preflight FAILS on example.com, CHANGE_ME, livewire2024. acc.local is OK.
#
# Usage:
#   REF=main ./scripts/deploy.sh              # default: Apache + Prosody only
#   APPLY_LB=1 ./scripts/deploy.sh            # also apply HAProxy/Keepalived (dangerous)
#   FIRST_INSTALL=1 APPLY_LB=1 ./scripts/deploy.sh
#
# Env:
#   REPO_DIR   Checkout directory (default: livewire-portal)
#   REF        Branch or tag to deploy (default: main). Alias: BRANCH
#   APPLY_LB   Set to 1 to copy HAProxy/Keepalived from repo examples into /etc
#              (refused unless FIRST_INSTALL=1 or FORCE_LB=1, and preflight passes)
#   FIRST_INSTALL  Allow creating missing LB configs from examples (still runs preflight)
#   FORCE_LB   Override "live file exists" guard (still runs preflight; use with care)
#   SKIP_PULL  Set to 1 if already on the desired ref in REPO_DIR
#
set -euo pipefail

REPO_DIR="${REPO_DIR:-livewire-portal}"
REF="${REF:-${BRANCH:-main}}"
APPLY_LB="${APPLY_LB:-0}"
FIRST_INSTALL="${FIRST_INSTALL:-0}"
FORCE_LB="${FORCE_LB:-0}"
SKIP_PULL="${SKIP_PULL:-0}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/livewire-portal}"
STAMP="$(date +%Y%m%d-%H%M%S)"

HAPROXY_SRC="configs/haproxy/haproxy.cfg.example"
HAPROXY_DST="/etc/haproxy/haproxy.cfg"
KEEPALIVED_SRC="configs/keepalived/keepalived.conf.example"
KEEPALIVED_DST="/etc/keepalived/keepalived.conf"
PROSODY_SRC="configs/prosody/prosody.cfg.lua.example"
PROSODY_DST="/etc/prosody/prosody.cfg.lua"

die() { echo "ERROR: $*" >&2; exit 1; }

backup_path() {
  local src="$1"
  if [[ -e "$src" ]]; then
    mkdir -p "$BACKUP_ROOT/$STAMP"
    cp -a "$src" "$BACKUP_ROOT/$STAMP/$(basename "$src")"
    echo "  backed up $src -> $BACKUP_ROOT/$STAMP/"
  fi
}

# Fail if a file that is about to be installed still has placeholders.
# example.com = hard fail; *.acc.local is the intended zone.
preflight_file() {
  local f="$1"
  local label="$2"
  [[ -f "$f" ]] || die "missing $label: $f"
  if grep -Eiq 'CHANGE_ME|livewire2024|example\.com' "$f"; then
    die "$label still contains CHANGE_ME / livewire2024 / example.com: $f\n       Use portal/xmpp/mail.acc.local (or edit before APPLY_LB)."
  fi
}

echo "[1/6] Repo at REF=$REF ..."
if [[ "$SKIP_PULL" != "1" ]]; then
  if [[ -d "$REPO_DIR/.git" ]]; then
    cd "$REPO_DIR"
    git fetch origin
    git checkout "$REF"
    git pull --ff-only origin "$REF" 2>/dev/null || git pull --ff-only || true
    git checkout "$REF"
  elif [[ -d "$REPO_DIR" ]]; then
    die "$REPO_DIR exists but is not a git checkout"
  else
    git clone https://github.com/mike0615/livewire-portal.git "$REPO_DIR"
    cd "$REPO_DIR"
    git checkout "$REF"
  fi
else
  cd "$REPO_DIR" || die "SKIP_PULL=1 but cannot cd $REPO_DIR"
fi

echo "[2/6] Backing up live configs (if present)..."
backup_path /etc/httpd/conf.d
backup_path "$PROSODY_DST"
backup_path "$HAPROXY_DST"
backup_path "$KEEPALIVED_DST"

echo "[3/6] Apache configs..."
sudo mkdir -p /etc/httpd/conf.d
sudo cp -r configs/apache/* /etc/httpd/conf.d/
sudo apachectl configtest

echo "[4/6] Prosody config..."
if grep -Eiq 'CHANGE_ME|example\.com' "$PROSODY_SRC"; then
  echo "WARNING: Prosody example still has placeholders — prefer xmpp.acc.local; edit $PROSODY_DST after copy if needed."
fi
backup_path "$PROSODY_DST"
sudo cp "$PROSODY_SRC" "$PROSODY_DST"
if command -v prosodyctl >/dev/null 2>&1; then
  sudo prosodyctl check config || sudo prosodyctl check || die "Prosody configtest failed"
else
  echo "WARNING: prosodyctl not found; skipped Prosody configtest"
fi

echo "[5/6] HAProxy + Keepalived..."
if [[ "$APPLY_LB" == "1" ]]; then
  if [[ -f "$HAPROXY_DST" || -f "$KEEPALIVED_DST" ]]; then
    if [[ "$FORCE_LB" != "1" && "$FIRST_INSTALL" != "1" ]]; then
      die "Live LB configs exist ($HAPROXY_DST / $KEEPALIVED_DST).\n       Refusing to overwrite rotated secrets with repo examples.\n       Manage LB configs on the host (or site-local path), or set FIRST_INSTALL=1 / FORCE_LB=1 after preflight."
    fi
  fi
  preflight_file "$HAPROXY_SRC" "HAProxy example"
  preflight_file "$KEEPALIVED_SRC" "Keepalived example"
  if grep -Eiq 'wp-login\.php' "$HAPROXY_SRC"; then
    die "HAProxy example still health-checks /wp-login.php (checklist §6). Fix before APPLY_LB."
  fi
  backup_path "$HAPROXY_DST"
  backup_path "$KEEPALIVED_DST"
  sudo cp "$HAPROXY_SRC" "$HAPROXY_DST"
  sudo cp "$KEEPALIVED_SRC" "$KEEPALIVED_DST"
  if command -v haproxy >/dev/null 2>&1; then
    sudo haproxy -c -f "$HAPROXY_DST" || die "HAProxy configtest failed"
  else
    die "haproxy binary not found; cannot configtest"
  fi
  if command -v keepalived >/dev/null 2>&1; then
    echo "  Keepalived binary present; auth_pass must already be rotated (preflight passed)."
  fi
else
  echo "  Skipping LB apply (default). Live Keepalived/HAProxy left untouched."
  echo "  Set APPLY_LB=1 only for first install or after preparing non-placeholder examples."
  if [[ -f "$HAPROXY_DST" ]] && command -v haproxy >/dev/null 2>&1; then
    sudo haproxy -c -f "$HAPROXY_DST" || die "Existing HAProxy config failed configtest"
  fi
fi

echo "[6/6] Restarting services..."
sudo systemctl restart httpd
sudo systemctl restart prosody
if [[ "$APPLY_LB" == "1" ]]; then
  sudo systemctl restart haproxy
  sudo systemctl restart keepalived
else
  if systemctl is-active --quiet haproxy; then
    sudo systemctl reload haproxy 2>/dev/null || sudo systemctl restart haproxy
  fi
fi

echo "Deploy complete (REF=$REF)."
echo "Next: WP-CLI activate theme/plugins if needed."
echo "Smoke: SSO -> dashboard -> chat -> mail -> files."
echo "Multi-node: roll secondary sites first; VIP site last; never APPLY_LB over rotated secrets."
