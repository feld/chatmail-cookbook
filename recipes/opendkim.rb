#
# Cookbook:: chatmail
# Recipe:: opendkim
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package %w(opendkim opendkim-tools)

directory '/etc/dkimkeys' do
  owner 'opendkim'
  group 'opendkim'
  mode '0700'
end

directory '/etc/opendkim' do
  owner 'opendkim'
  group 'opendkim'
  mode '0750'
end

cookbook_file '/etc/opendkim/screen.lua' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[opendkim.service]', :delayed
end

cookbook_file '/etc/opendkim/final.lua' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[opendkim.service]', :delayed
end

template '/etc/opendkim.conf' do
  owner 0
  group 0
  mode '0644'
  variables({ 'domain' => node['chatmail']['domain'], 'dkim_selector' => node['chatmail']['dkim_selector'] })
  notifies :restart, 'service[opendkim.service]', :delayed
end

template '/etc/dkimkeys/KeyTable' do
  owner 'opendkim'
  group 'opendkim'
  mode '0644'
  variables({ 'domain' => node['chatmail']['domain'], 'dkim_selector' => node['chatmail']['dkim_selector'] })
  notifies :restart, 'service[opendkim.service]', :delayed
end

template '/etc/dkimkeys/SigningTable' do
  owner 'opendkim'
  group 'opendkim'
  mode '0644'
  variables({ 'domain' => node['chatmail']['domain'], 'dkim_selector' => node['chatmail']['dkim_selector'] })
  notifies :restart, 'service[opendkim.service]', :delayed
end

execute 'Generate OpenDKIM domain keys' do
  command "opendkim-genkey -D /etc/dkimkeys -d #{node['chatmail']['domain']} -s #{node['chatmail']['dkim_selector']}"
  not_if { ::File.exist?("/etc/dkimkeys/#{node['chatmail']['dkim_selector']}.private") }
  notifies :restart, 'service[opendkim.service]', :delayed
end

directory '/etc/dkimkeys' do
  owner 'opendkim'
  group 'opendkim'
  mode '0700'
  recursive true
end

service 'opendkim.service' do
  action [:enable, :start]
end

directory '/etc/systemd/system/opendkim.service.d'

file '/etc/systemd/system/opendkim.service.d/10-prevent-memory-leak.conf' do
  owner 0
  group 0
  mode '0644'
  content <<~EOU
[Service]
Restart=always
RuntimeMaxSec=1d
EOU
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[opendkim.service]', :delayed
end

execute 'systemctl daemon-reload' do
  action :nothing
end
