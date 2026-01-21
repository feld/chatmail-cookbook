#
# Cookbook:: chatmail
# Recipe:: start_services
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Safe to start services now

# syslogd is normally enabled, except in a jail
if platform_family?('freebsd')
  service 'syslogd' do
    action [:enable, :start]
  end
end

service 'unbound' do
  action :start
  subscribes :restart, 'package[unbound]', :delayed
end

# Chatmaild services
%w(chatmail-metadata doveauth lastlogin).each do |s|
  service s do
    action :start
    subscribes :restart, 'execute[install chatmaild]', :delayed
  end
end

# Filtermail specific when packages update
%w(filtermail filtermail-incoming).each do |s|
  service s do
    action :start
    subscribes :restart, 'package[filtermail]', :delayed if platform_family?('freebsd')
  end
end

if platform_family?('debian')
  service 'fcgiwrap.socket' do
    action :start
    subscribes :restart, 'package[fcgiwrap]', :delayed
  end
end

service 'fcgiwrap' do
  action :start
  subscribes :restart, 'package[fcgiwrap]', :delayed
end

service 'mtail' do
  action :start
  subscribes :restart, 'package[mtail]', :delayed
end

turn_service = node['chatmail']['turnservice']

service turn_service do
  action :start
  subscribes :restart, 'package[chatmail-turn]', :delayed if platform_family?('freebsd')
end

service 'iroh-relay' do
  action :start
  only_if { node['chatmail']['iroh_relay'] }
  subscribes :restart, 'package[iroh-relay]', :delayed if platform_family?('freebsd')
end

opendkim_service = node['opendkim']['service']

service opendkim_service do
  action :start
  subscribes :restart, 'package[opendkim-devel]', :delayed if platform_family?('freebsd')
  subscribes :restart, 'package[opendkim]', :delayed if platform_family?('debian')
end

service 'dovecot' do
  action :start
  subscribes :restart, 'package[dovecot]', :delayed
end

service 'postfix' do
  action :start
  subscribes :restart, 'package[postfix]', :delayed
end
