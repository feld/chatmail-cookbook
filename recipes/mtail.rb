#
# Cookbook:: chatmail
# Recipe:: chatmaild
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package 'mtail'

cookbook_file '/etc/mtail/delivered_mail.mtail' do
  user 0
  group 0
  mode '0644'
  notifies :restart, 'service[mtail.service]', :delayed
end

directory '/etc/systemd/system/mtail.service.d'

file '/etc/systemd/system/mtail.service.d/override.conf' do
  owner 0
  group 0
  mode '0644'
  content <<~EOU
[Service]
ExecCondition=
ExecStart=
ExecStart=/bin/sh -c 'journalctl -f -o short-iso -n 0 | /usr/bin/mtail $${HOST:+--address $$HOST} $${PORT:+--port $$PORT} --progs /etc/mtail --logtostderr --logs -'
EOU
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[mtail.service]', :delayed
end

service 'mtail.service' do
  action [:enable, :start]
end

execute 'systemctl daemon-reload' do
  action :nothing
end
