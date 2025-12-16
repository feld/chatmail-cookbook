#
# Cookbook:: chatmail
# Recipe:: mtail
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_etc = node['etcdir']
platform_bin = node['bindir']
mtail_path = "#{platform_bin}/mtail"

directory "#{platform_etc}/mtail"

cookbook_file "#{platform_etc}/mtail/delivered_mail.mtail" do
  user 0
  group 0
  mode '0644'
  notifies :restart, 'service[mtail]', :delayed
end

if platform_family?('freebsd')
  mtail_sysrc = 'mtail_args="-address 127.0.0.1 -port 3903 -progs #{platform_etc}/mtail -logs /var/log/maillog"'
  execute 'configure mtail' do
    command "sysrc #{mtail_sysrc}"
    not_if "sysrc -c #{mtail_sysrc}"
    notifies :restart, 'service[mtail]', :delayed
  end
else
  directory '/etc/systemd/system/mtail.service.d'

  file '/etc/systemd/system/mtail.service.d/override.conf' do
    owner 0
    group 0
    mode '0644'
    content <<~EOU
    [Service]
    ExecCondition=
    ExecStart=
    ExecStart=/bin/sh -c 'journalctl -f -o short-iso -n 0 | #{mtail_path} $${HOST:+--address $$HOST} $${PORT:+--port $$PORT} --progs #{platform_etc}/mtail --logtostderr --logs -'
    EOU
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :restart, 'service[mtail]', :delayed
  end

  execute 'systemctl daemon-reload' do
    action :nothing
  end
end

service 'mtail' do
  action [:enable, :start]
end
