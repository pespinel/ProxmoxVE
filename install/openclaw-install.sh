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
$STD apt install -y \
  ca-certificates \
  build-essential \
  python3 \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

get_lxc_ip

msg_info "Installing OpenClaw (Patience)"
$STD npm install --global openclaw@latest
msg_ok "Installed OpenClaw"

msg_info "Creating Workspace Directory"
mkdir -p /root/.openclaw/workspace
msg_ok "Created Workspace Directory"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.openclaw
ExecStart=/usr/bin/openclaw gateway --port 18789
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openclaw
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
