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

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  gnupg \
  ca-certificates \
  openssl
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing OpenClaw (Patience)"
$STD npm install --global openclaw@latest
msg_ok "Installed OpenClaw"

msg_info "Configuring OpenClaw Gateway"
mkdir -p /root/.openclaw/workspace
GATEWAY_TOKEN=$(openssl rand -hex 32)

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
    "bind": "localhost",
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  }
}
EOF
msg_ok "Configured OpenClaw Gateway"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/.openclaw
ExecStart=openclaw gateway
Restart=on-failure
RestartSec=10
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now openclaw
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
