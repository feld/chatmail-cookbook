#
# Cookbook:: chatmail
# Recipe:: dovecot
#
# Copyright:: 2023, The Authors, All Rights Reserved.

group 'vmail' do
  notifies :restart, 'service[dovecot.service]', :delayed
end

user 'vmail' do
  gid 'vmail'
  home '/home/vmail'
  manage_home true
  shell '/bin/sh'
  notifies :restart, 'service[dovecot.service]', :delayed
end

cookbook_file '/etc/apt/keyrings/obs-home-deltachat.gpg' do
  owner 0
  group 0
  mode '0444'
end

apt_repository 'DeltaChat_OBS' do
  components ['./']
  distribution ''
  uri 'https://download.opensuse.org/repositories/home:/deltachat/Debian_12/'
  options ['signed-by=/etc/apt/keyrings/obs-home-deltachat.gpg']
  action :add
end

package %w(dovecot-imapd dovecot-lmtpd rsync)

cookbook_file '/etc/dovecot/push_notification.lua' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[dovecot.service]', :delayed
end

template '/etc/dovecot/dovecot.conf' do
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :restart, 'service[dovecot.service]', :delayed
end

cookbook_file '/etc/dovecot/auth.conf' do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[dovecot.service]', :delayed
end

service 'dovecot.service' do
  action [:enable, :start]
end

template '/etc/cron.d/expunge' do
  source 'expunge.cron.erb'
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
end
