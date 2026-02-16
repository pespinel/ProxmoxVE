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

msg_info "Creating Workspace"
mkdir -p /root/.openclaw/workspace
msg_ok "Created Workspace"

APPLICATION="OpenClaw"
motd_ssh
customize
cleanup_lxc
