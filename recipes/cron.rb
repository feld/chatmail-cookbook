#
# Cookbook:: chatmail
# Recipe:: cron
#
# Copyright:: 2023, The Authors, All Rights Reserved.

service 'cron' do
  action [:enable, :start]
end

chatmail_bin = node['chatmail']['bin_dir']
config_path = node['chatmail']['config_path']

template '/etc/cron.d/chatmail' do
  source 'chatmail.cron.erb'
  owner 0
  group 0
  mode '0644'
  variables({ 'chatmail_bin' => chatmail_bin, 'config_file' => config_path, 'config' => node['chatmail'] })
end
