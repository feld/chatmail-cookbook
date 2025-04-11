#
# Cookbook:: chatmail
# Recipe:: postfix
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package %w(postfix)

cookbook_file '/etc/postfix/login_map' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[postfix.service]', :delayed
end

cookbook_file '/etc/postfix/submission_header_cleanup' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[postfix.service]', :delayed
end

template '/etc/postfix/main.cf' do
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :restart, 'service[postfix.service]', :delayed
end

template '/etc/postfix/master.cf' do
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :restart, 'service[postfix.service]', :delayed
end

group 'opendkim' do
  append true
  members ['postfix']
  action :modify
  notifies :restart, 'service[postfix.service]', :delayed
end

directory '/var/spool/postfix/opendkim' do
  owner 'opendkim'
  group 'opendkim'
  mode '0750'
  notifies :restart, 'service[opendkim.service]', :delayed
end

service 'postfix.service' do
  action [:enable, :start]
end

service 'opendkim.service' do
  action :nothing
end
