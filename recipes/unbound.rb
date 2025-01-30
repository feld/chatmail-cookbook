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
