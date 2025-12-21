#
# Cookbook:: chatmail
# Recipe:: start_services
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Safe to start services now

service 'unbound' do
  action :start
end

# Chatmaild services
%w(chatmail-metadata doveauth filtermail filtermail-incoming lastlogin).each do |s|
  service s do
    action :start
  end
end

if platform_family?('debian')
  service 'fcgiwrap.socket' do
    action :start
  end
end

service 'fcgiwrap' do
  action :start
end

service 'mtail' do
  action :start
end

turn_service = node['chatmail']['turnservice']

service turn_service do
  action :start
end

service 'iroh-relay' do
  action :start
  only_if { node['chatmail']['iroh_relay'] }
end

opendkim_service = node['opendkim']['service']

service opendkim_service do
  action :start
end

service 'dovecot' do
  action :start
end

service 'postfix' do
  action :start
end
