#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: ashtonchase
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/mellow-fox/TidyQuest

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  git \
  nodejs \
  npm
msg_ok "Installed Dependencies"

msg_info "Cloning TidyQuest"
cd /opt
$STD git clone https://github.com/mellow-fox/TidyQuest.git tidyquest
cd tidyquest
RELEASE=$(git describe --tags --abbrev=0)
msg_ok "Cloned TidyQuest ${RELEASE}"

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

msg_info "Configuring TidyQuest"
JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c48)
cat <<EOF >/opt/tidyquest/.env
NODE_ENV=production
PORT=3000
JWT_SECRET=${JWT_SECRET}
TZ=UTC
EOF
mkdir -p /opt/tidyquest/data
echo "${RELEASE}" > /opt/tidyquest_version.txt
msg_ok "Configured TidyQuest"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tidyquest.service
[Unit]
Description=TidyQuest Family Task Manager
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tidyquest
EnvironmentFile=/opt/tidyquest/.env
ExecStart=/usr/bin/node /opt/tidyquest/server/dist/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tidyquest
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc