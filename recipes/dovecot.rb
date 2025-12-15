#
# Cookbook:: chatmail
# Recipe:: dovecot
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_etc = node['etcdir']
chatmail_metadata_sock = node['chatmail']['metadata_sock']
chatmail_lastlogin_sock = node['chatmail']['lastlogin_sock']
doveauth_sock = node['chatmail']['doveauth_sock']

cookbook_file "#{platform_etc}/dovecot/push_notification.lua" do
  owner 0
  group 0
  mode '0644'
end

# Generate DH parameters file if it doesn't exist
# On FreeBSD we'll put it in platform_etc, on Debian it can stay in share
dh_params_file = if platform?('freebsd')
                   "#{platform_etc}/dovecot/dh.pem"
                 else
                   '/usr/share/dovecot/dh.pem'
                 end

# Create directory for DH params if needed
directory ::File.dirname(dh_params_file) do
  owner 0
  group 0
  mode '0755'
  recursive true
  action :create
end

# Generate DH parameters if the file doesn't exist
execute 'generate dhparams' do
  command "openssl dhparam -out #{dh_params_file} 2048"
  creates dh_params_file
  not_if { ::File.exist?(dh_params_file) }
end

template "#{platform_etc}/dovecot/dovecot.conf" do
  owner 0
  group 0
  mode '0644'
  variables(
    'config' => node['chatmail'],
    'ssl_dh_path' => "<#{dh_params_file}",
    'dovecot_config_dir' => "#{platform_etc}/dovecot",
    'chatmail_metadata_sock' => chatmail_metadata_sock,
    'chatmail_lastlogin_sock' => chatmail_lastlogin_sock
  )
  notifies :restart, 'service[dovecot]', :delayed
end

template "#{platform_etc}/dovecot/auth.conf" do
  owner 0
  group 0
  mode '0644'
  variables(
    'doveauth_sock' => doveauth_sock
  )
  notifies :restart, 'service[dovecot]', :delayed
end

service 'dovecot' do
  action [:enable, :start]
end
