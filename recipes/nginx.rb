#
# Cookbook:: chatmail
# Recipe:: nginx
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package 'nginx'

template '/etc/nginx/nginx.conf' do
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :restart, 'service[nginx.service]', :delayed
end

service 'nginx.service' do
  action [:enable, :start]
end

directory '/usr/lib/cgi-bin'

cookbook_file '/usr/lib/cgi-bin/newemail.py' do
  owner 0
  group 0
  mode '0755'
end

directory '/var/www/html/.well-known/autoconfig/mail' do
  recursive true
end

template '/var/www/html/.well-known/mta-sts.txt' do
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
end

template '/var/www/html/.well-known/autoconfig/mail/config-v1.1.xml' do
  owner 0
  group 0
  source 'autoconfig.xml.erb'
  mode '0644'
  variables({ 'config' => node['chatmail'] })
end
