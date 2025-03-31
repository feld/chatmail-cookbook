#
# Cookbook:: chatmail
# Recipe:: chatmaild
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package %w(acl python3-virtualenv)

remote_base_dir = '/usr/local/lib/chatmaild'
remote_venv_dir = remote_base_dir + '/venv'
chatmail_bin = remote_venv_dir + '/bin'
config_path = remote_base_dir + '/chatmail.ini'
release = node['chatmaild']['release']

directory remote_base_dir + '/dist' do
  recursive true
end

cookbook_file remote_base_dir + "/dist/chatmaild-#{release}.tar.gz" do
  owner 0
  group 0
  mode '0644'
  action :create
  notifies :run, 'execute[remove old chatmaild]', :immediately
end

execute 'remove old chatmaild' do
  command "rm -rf #{remote_venv_dir}"
  action :nothing
end

execute 'virtualenv' do
  cwd Chef::Config[:file_cache_path]
  command <<~EOF
    /usr/bin/virtualenv #{remote_venv_dir}
  EOF
  not_if { Dir.exist?(remote_venv_dir) }
end

execute 'install chatmaild' do
  environment({ 'VIRTUAL_ENV' => remote_venv_dir })
  command <<~EOF
    #{chatmail_bin}/pip install #{remote_base_dir}/dist/chatmaild-#{release}.tar.gz
  EOF
  not_if { ::File.exist?(chatmail_bin + '/deltachat-rpc-server') }
  notifies :restart, 'systemd_unit[doveauth.service]', :delayed
  notifies :restart, 'systemd_unit[chatmail-metadata.service]', :delayed
  notifies :restart, 'systemd_unit[echobot.service]', :delayed
  notifies :restart, 'systemd_unit[filtermail.service]', :delayed
  notifies :restart, 'systemd_unit[lastlogin.service]', :delayed
end

template config_path do
  owner 0
  group 0
  source 'chatmail.ini.erb'
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :restart, 'systemd_unit[doveauth.service]', :delayed
  notifies :restart, 'systemd_unit[chatmail-metadata.service]', :delayed
  notifies :restart, 'systemd_unit[echobot.service]', :delayed
  notifies :restart, 'systemd_unit[filtermail.service]', :delayed
  notifies :restart, 'systemd_unit[lastlogin.service]', :delayed
end

execpath = chatmail_bin + '/doveauth'
systemd_unit 'doveauth.service' do
  content <<~EOU
[Unit]
Description=Chatmail dict authentication proxy for dovecot

[Service]
ExecStart=#{execpath} /run/doveauth/doveauth.socket #{config_path}
Restart=always
RestartSec=30
User=vmail
RuntimeDirectory=doveauth
UMask=0077

[Install]
WantedBy=multi-user.target
EOU
  action [:create, :enable, :start]
end

execpath = chatmail_bin + '/chatmail-metadata'
systemd_unit 'chatmail-metadata.service' do
  content <<~EOU
[Unit]
Description=Chatmail dict proxy for IMAP METADATA

[Service]
ExecStart=#{execpath} /run/chatmail-metadata/metadata.socket #{config_path}
Restart=always
RestartSec=30
User=vmail
RuntimeDirectory=chatmail-metadata
UMask=0077

[Install]
WantedBy=multi-user.target
EOU
  action [:create, :enable, :start]
end

group 'echobot' do
  notifies :restart, 'systemd_unit[echobot.service]', :delayed
end

user 'echobot' do
  gid 'echobot'
  home '/home/echobot'
  shell '/bin/sh'
  notifies :restart, 'systemd_unit[echobot.service]', :delayed
end

execpath = chatmail_bin + '/echobot'
systemd_unit 'echobot.service' do
  content <<~EOU
[Unit]
Description=Chatmail echo bot for testing it works

[Service]
ExecStart=#{execpath} #{config_path}
Environment="PATH=#{remote_venv_dir}:$PATH"
Restart=always
RestartSec=30

User=echobot
Group=echobot

# Create /var/lib/echobot
StateDirectory=echobot

# Create /run/echobot
#
# echobot stores /run/echobot/password
# with a password there, which doveauth then reads.
RuntimeDirectory=echobot

WorkingDirectory=/var/lib/echobot

# Apply security restrictions suggested by
#   systemd-analyze security echobot.service
CapabilityBoundingSet=
LockPersonality=true
MemoryDenyWriteExecute=true
NoNewPrivileges=true
PrivateDevices=true
PrivateMounts=true
PrivateTmp=true

# We need to know about doveauth user to give it access to /run/echobot/password
PrivateUsers=false

ProtectClock=true
ProtectControlGroups=true
ProtectHostname=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectProc=noaccess

# Should be "strict", but we currently write /accounts folder in a protected path
ProtectSystem=full

RemoveIPC=true
RestrictAddressFamilies=AF_INET AF_INET6
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true
SystemCallArchitectures=native
SystemCallFilter=~@clock
SystemCallFilter=~@cpu-emulation
SystemCallFilter=~@debug
SystemCallFilter=~@module
SystemCallFilter=~@mount
SystemCallFilter=~@obsolete
SystemCallFilter=~@raw-io
SystemCallFilter=~@reboot
SystemCallFilter=~@resources
SystemCallFilter=~@swap
UMask=0077

[Install]
WantedBy=multi-user.target
EOU
  action [:create, :enable, :start]
end

group 'filtermail' do
  notifies :restart, 'systemd_unit[filtermail.service]', :delayed
end

user 'filtermail' do
  gid 'filtermail'
  home '/home/filtermail'
  shell '/bin/sh'
  notifies :restart, 'systemd_unit[filtermail.service]', :delayed
end

execpath = chatmail_bin + '/filtermail'
systemd_unit 'filtermail.service' do
  content <<~EOU
[Unit]
Description=Chatmail Postfix before queue filter

[Service]
ExecStart=#{execpath} #{config_path}
Restart=always
RestartSec=30
User=filtermail

[Install]
WantedBy=multi-user.target
EOU
  action [:create, :enable, :start]
end

execpath = chatmail_bin + '/lastlogin'
systemd_unit 'lastlogin.service' do
  content <<~EOU
[Unit]
Description=Dict proxy for last-login tracking

[Service]
ExecStart=#{execpath} /run/chatmail-lastlogin/lastlogin.socket #{config_path}
Restart=always
RestartSec=30
User=vmail
RuntimeDirectory=chatmail-lastlogin

[Install]
WantedBy=multi-user.target
EOU
  action [:create, :enable, :start]
end

template '/etc/cron.d/chatmail-metrics' do
  source 'metrics.cron.erb'
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'], 'chatmail_bin' => chatmail_bin })
end
