#
# Cookbook:: chatmail
# Recipe:: journald
#
# Copyright:: 2023, The Authors, All Rights Reserved.

template '/etc/systemd/journald.conf' do
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :restart, 'service[systemd-journald.service]', :immediately
end

service 'systemd-journald.service' do
  action :nothing
end

directory '/var/log/journal' do
  recursive true
  action :delete
end
