#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/ashtonchase/ProxmoxVED/feature/tidyquest/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: ashtonchase
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/mellow-fox/TidyQuest

APP="TidyQuest"
var_tags="${var_tags:-productivity;family;gamification}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/tidyquest ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Checking for updates"
  cd /opt/tidyquest
  $STD git fetch origin
  CURRENT=$(cat /opt/tidyquest_version.txt)
  LATEST=$(git describe --tags --abbrev=0)

  if [[ "${LATEST}" != "${CURRENT}" ]]; then
    msg_info "Updating ${APP} from ${CURRENT} to ${LATEST}"

    msg_info "Stopping Service"
    systemctl stop tidyquest
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/tidyquest/data /opt/tidyquest_data_backup
    cp /opt/tidyquest/.env /opt/tidyquest.env.bak
    msg_ok "Backed up Data"

    msg_info "Pulling latest code"
    $STD git checkout main
    $STD git pull origin main
    msg_ok "Pulled latest code"

    msg_info "Building Server"
    cd /opt/tidyquest/server
    $STD npm install
    $STD npm run build
    msg_ok "Built Server"

    msg_info "Building Client"
    cd /opt/tidyquest/client
    $STD npm install
    $STD npm run build
    msg_ok "Built Client"

    msg_info "Restoring Data"
    cp -r /opt/tidyquest_data_backup/. /opt/tidyquest/data
    rm -rf /opt/tidyquest_data_backup
    cp /opt/tidyquest.env.bak /opt/tidyquest/.env
    rm -f /opt/tidyquest.env.bak
    msg_ok "Restored Data"

    echo "${LATEST}" > /opt/tidyquest_version.txt

    msg_info "Starting Service"
    systemctl start tidyquest
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is at ${CURRENT}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3020${CL}"