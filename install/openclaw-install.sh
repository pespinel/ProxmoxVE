#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pespinel
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/OpenAgentsInc/openclaw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

: "${SSH_ROOT:=no}"
: "${PASSWORD:=}"
: "${SSH_AUTHORIZED_KEY:=}"
: "${app:=openclaw}"

msg_info "Installing Dependencies"
$STD apt install -y \
  curl \
  gnupg \
  ca-certificates \
  build-essential \
  python3 \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing OpenClaw (Patience)"
$STD npm install --global openclaw@latest
msg_ok "Installed OpenClaw"

msg_info "Setting up OpenClaw Gateway"
# Create workspace directory
mkdir -p /root/.openclaw/workspace

# Generate a secure token for gateway access
GATEWAY_TOKEN=$(openssl rand -hex 32)

# Configuration for LAN access
# User will configure LLM provider via Web UI
cat <<EOF >/root/.openclaw/openclaw.json
{
  "agents": {
    "defaults": {
      "workspace": "/root/.openclaw/workspace"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "meta": {
    "lastTouchedVersion": "2026.2.15",
    "lastTouchedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  }
}
EOF

# Save token for user reference
echo "${GATEWAY_TOKEN}" >/root/.openclaw/gateway-token.txt
chmod 600 /root/.openclaw/gateway-token.txt

msg_ok "Set up OpenClaw Gateway"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.openclaw
ExecStart=/usr/bin/openclaw gateway
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now openclaw
msg_ok "Created Service"

msg_info "Creating Access Information"
CONTAINER_IP=$(hostname -I | awk '{print $1}')
GATEWAY_TOKEN=$(cat /root/.openclaw/gateway-token.txt)

cat <<EOF >/root/openclaw-access.txt
================================================================================
  OPENCLAW - ACCESS INFORMATION
================================================================================

Container IP: ${CONTAINER_IP}
Gateway Port: 18789

WEB UI ACCESS:
--------------
Open in your browser:
  http://${CONTAINER_IP}:18789

Gateway Token (if required):
  ${GATEWAY_TOKEN}

INITIAL SETUP:
--------------
1. Access the Web UI from your browser
2. Add your AI provider API key (Anthropic, OpenAI, etc.)
3. Configure agents and start chatting

ALTERNATIVE - CLI WIZARD:
--------------------------
SSH into the container and run:
  openclaw onboard

SERVICE MANAGEMENT:
-------------------
Status:  systemctl status openclaw
Logs:    journalctl -u openclaw -f
Restart: systemctl restart openclaw

DOCUMENTATION:
--------------
https://docs.openclaw.ai/

================================================================================
EOF
msg_ok "Created Access Information"

export APPLICATION="OpenClaw"
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

CONTAINER_IP=$(hostname -I | awk '{print $1}')

cat <<EOF

╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║  ✓ OpenClaw installed successfully!                                 ║
║                                                                      ║
║  🌐 Access Web UI:                                                   ║
║     http://${CONTAINER_IP}:18789                                        ║
║                                                                      ║
║  📋 Complete info: /root/openclaw-access.txt                         ║
║                                                                      ║
║  Next step: Open the Web UI and add your AI provider API key        ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝

EOF
