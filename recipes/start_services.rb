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
    retries 2
  end
end

service 'unbound' do
  action :start
  subscribes :stop, 'package[unbound]', :before
  retries 2
end

# Chatmaild services
%w(chatmail-metadata doveauth lastlogin).each do |s|
  service s do
    action :start
    subscribes :stop, 'execute[install chatmaild]', :before
    retries 2
  end
end

# Filtermail specific when packages update
%w(filtermail filtermail-incoming).each do |s|
  service s do
    action :start
    subscribes :stop, 'package[filtermail]', :before if platform_family?('freebsd')
    retries 2
  end
end

if platform_family?('debian')
  service 'fcgiwrap.socket' do
    action :start
    subscribes :stop, 'package[fcgiwrap]', :before
    retries 2
  end
end

service 'fcgiwrap' do
  action :start
  subscribes :stop, 'package[fcgiwrap]', :before
  retries 2
end

service 'mtail' do
  action :start
  subscribes :stop, 'package[mtail]', :before
  retries 2
end

turn_service = node['chatmail']['turnservice']

service turn_service do
  action :start
  subscribes :stop, 'package[chatmail-turn]', :before
  retries 2
end

service 'iroh-relay' do
  action :start
  only_if { node['chatmail']['iroh_relay'] }
  subscribes :stop, 'package[iroh-relay]', :before
  retries 2
end

opendkim_service = node['opendkim']['service']

service opendkim_service do
  action :start
  subscribes :stop, 'package[opendkim-devel]', :before if platform_family?('freebsd')
  subscribes :stop, 'package[opendkim]', :before if platform_family?('debian')
  retries 2
end

service 'dovecot' do
  action :start
  subscribes :stop, 'package[dovecot]', :before
  retries 2
end

service 'postfix' do
  action :start
  subscribes :stop, 'package[postfix]', :before
  retries 2
end
