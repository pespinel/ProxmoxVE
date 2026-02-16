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
  ca-certificates \
  build-essential \
  python3 \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing OpenClaw (Patience)"
$STD npm install --global openclaw@latest
msg_ok "Installed OpenClaw"

msg_info "Configuring OpenClaw"
mkdir -p /root/.openclaw/workspace
GATEWAY_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
cat <<EOF >/root/.openclaw/openclaw.json
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "lan",
    "auth": {
      "mode": "password",
      "password": "${GATEWAY_PASSWORD}"
    },
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    }
  }
}
EOF
echo "${GATEWAY_PASSWORD}" >~/openclaw.creds
msg_ok "Configured OpenClaw"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.openclaw
ExecStart=openclaw gateway
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openclaw
msg_ok "Created Service"

APPLICATION="OpenClaw"
motd_ssh
customize
cleanup_lxc
