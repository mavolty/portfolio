#!/usr/bin/env bash
# Usage: bash deploy.sh
# Requires: ssh alias "personal" in ~/.ssh/config pointing at your VPS
set -euo pipefail

PORTFOLIO_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE_HOST="personal"
REMOTE_DIR="/var/www/portfolio"

# Stamp cache-bust version into stylesheet link (YYYYMMDDHHmm)
VER="$(date -u +%Y%m%d%H%M)"
sed -i "s|styles\.css?v=[^\"']*|styles.css?v=${VER}|" "${PORTFOLIO_DIR}/portfolio.html"
echo "→ cache-bust version: ${VER}"

echo "→ Syncing to ${REMOTE_HOST}:${REMOTE_DIR}"

rsync -avz --delete \
  --exclude '.git' \
  --exclude 'deploy.sh' \
  --exclude 'nginx.conf' \
  "${PORTFOLIO_DIR}/" "${REMOTE_HOST}:${REMOTE_DIR}/"

echo "✓ Done — https://shusain.xyz"
