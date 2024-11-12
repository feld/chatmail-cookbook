#
# Cookbook:: chatmail
# Recipe:: journald
#
# Copyright:: 2023, The Authors, All Rights Reserved.

cookbook_file '/etc/systemd/journald.conf' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[systemd-journald.service]', :immediately
end

service 'systemd-journald.service' do
  action :nothing
end
