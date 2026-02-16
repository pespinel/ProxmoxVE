#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: pespinel
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/OpenAgentsInc/openclaw

APP="OpenClaw"
var_tags="${var_tags:-ai;automation}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/openclaw.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  msg_info "Updating ${APP}"
  $STD npm install -g openclaw@latest
  msg_ok "Updated ${APP}"

  msg_info "Restarting ${APP}"
  systemctl restart openclaw
  msg_ok "Restarted ${APP}"

  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:18789${CL}"
echo -e "${INFO}${YW} Gateway password is stored in:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}/root/openclaw.creds${CL}"
