#
# Cookbook:: chatmail
# Recipe:: _chatmaild_debian
#
# Copyright:: 2023, The Authors, All Rights Reserved.

chatmail_bin = node['chatmail']['bin_dir']
config_path = node['chatmail']['config_path']

template '/etc/systemd/system/doveauth.service' do
  source 'doveauth.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: chatmail_bin + '/doveauth',
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[doveauth]', :delayed
end

template '/etc/systemd/system/chatmail-metadata.service' do
  source 'chatmail-metadata.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: chatmail_bin + '/chatmail-metadata',
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[chatmail-metadata]', :delayed
end

template '/etc/systemd/system/filtermail.service' do
  source 'filtermail.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: chatmail_bin + '/chatmail-metadata',
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[filtermail]', :delayed
end

template '/etc/systemd/system/filtermail-incoming.service' do
  source 'filtermail-incoming.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: chatmail_bin + '/filtermail',
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[filtermail-incoming]', :delayed
end

template '/etc/systemd/system/lastlogin.service' do
  source 'lastlogin.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: chatmail_bin + '/lastlogin',
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[lastlogin]', :delayed
end

execute 'systemctl daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end
