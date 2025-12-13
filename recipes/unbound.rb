#
# Cookbook:: chatmail
# Recipe:: unbound
#
# Copyright:: 2023, The Authors, All Rights Reserved.

node['etcdir']
node['unbound']['config_dir']
unbound_anchor_bin = node['unbound']['anchor_bin']
config_file = node['unbound']['config_file']
trust_anchor = node['unbound']['trust_anchor']

cookbook_file config_file do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[unbound]', :immediately
end

execute unbound_anchor_bin do
  command "#{unbound_anchor_bin} -a #{trust_anchor} || true"
  not_if { ::File.exist?(trust_anchor.to_s) }
  notifies :restart, 'service[unbound]', :immediately
end

service 'unbound' do
  action [:enable, :start]
end

if platform?('freebsd')
  # Disable resolvconf to prevent it from overwriting our resolv.conf
  file '/etc/resolvconf.conf' do
    owner 0
    group 0
    mode '0644'
    content 'resolvconf="NO"'
    action :create
  end
end

if platform_family?('debian')
  # Marking this file non-executable disables this "hook"
  # which can force Unbound to forward requests through the
  # default DNS servers
  file '/etc/resolvconf/update.d/unbound' do
    mode '0644'
  end

  # Broken, ancient, unused
  # https://github.com/NLnetLabs/unbound/issues/1161
  service 'unbound-resolvconf.service' do
    action [:disable, :stop]
  end

  package 'systemd-resolved' do
    action :purge
  end
end

link '/etc/resolv.conf' do
  action :delete
  only_if { ::File.symlink?('/etc/resolv.conf') }
end

file '/etc/resolv.conf' do
  owner 0
  group 0
  mode '0644'
  content <<~EOU
search .
nameserver 127.0.0.1
nameserver 208.67.222.222
nameserver 208.67.220.220
EOU
end
