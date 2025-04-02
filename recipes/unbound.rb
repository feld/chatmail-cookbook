#
# Cookbook:: chatmail
# Recipe:: unbound
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package %w(unbound unbound-anchor dnsutils)

execute 'unbound-anchor' do
  command "unbound-anchor -a /var/lib/unbound/root.key || true"
  not_if { ::File.exist?('/var/lib/unbound/root.key') }
  notifies :restart, 'service[unbound.service]', :immediately
end

service 'unbound.service' do
  action [:enable, :start]
end

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

cookbook_file '/etc/unbound/unbound.conf.d/unbound.conf' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[unbound.service]', :immediately
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

package 'systemd-resolved' do
  action :purge
end
