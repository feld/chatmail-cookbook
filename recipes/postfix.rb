#
# Cookbook:: chatmail
# Recipe:: postfix
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package %w(postfix postfix-mta-sts-resolver)

cookbook_file '/etc/mta-sts-daemon.yml' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[postfix-mta-sts-resolver.service]', :delayed
end

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

service 'postfix-mta-sts-resolver.service' do
  action [:enable, :start]
end

service 'postfix.service' do
  action [:enable, :start]
end
