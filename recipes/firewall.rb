#
# Cookbook:: chatmail
# Recipe:: firewall
#
# Copyright:: 2026, The Authors, All Rights Reserved.

default_route_iface = node['network']['interfaces'].find do |iface, data|
  data['addresses'].any? do |addr, info|
    info['family'] == 'inet' && addr == node['ipaddress']
  end
end&.first

freebsd_kld 'pf' do
  loader true
  action :load
end

freebsd_kld 'pflog' do
  loader true
  action :load
end

template '/etc/pf.conf' do
  owner 0
  group 0
  mode '0644'
  verify '/sbin/pfctl -n -f %{path}'
  variables(default_route_iface: default_route_iface)
#  notifies :reload, 'service[pf]', :delayed
end

#freebsd_sysrc 'pf_rules' do
#  value '/etc/pf.conf'
#end
#
#service 'pf' do
#  action [:enable, :start]
#  supports [:reload]
#end
#
#service 'pflog' do
#  action [:enable, :start]
#end
