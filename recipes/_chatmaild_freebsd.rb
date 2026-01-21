#
# Cookbook:: chatmail
# Recipe:: _chatmaild_freebsd
#
# Copyright:: 2023, The Authors, All Rights Reserved.

chatmail_bin = node['chatmail']['bin_dir']
config_path = node['chatmail']['config_path']

template '/usr/local/etc/rc.d/doveauth' do
  owner 0
  group 0
  mode '0555'
  variables(
    execpath: chatmail_bin + '/doveauth',
    config_path: config_path
  )
  notifies :restart, 'service[doveauth]', :delayed
end

template '/usr/local/etc/rc.d/chatmail-metadata' do
  owner 0
  group 0
  mode '0555'
  variables(
    execpath: chatmail_bin + '/chatmail-metadata',
    config_path: config_path
  )
  notifies :restart, 'service[chatmail-metadata]', :delayed
end

template '/usr/local/etc/rc.d/filtermail' do
  owner 0
  group 0
  mode '0555'
  variables(
    execpath: '/usr/local/bin/filtermail',
    config_path: config_path
  )
  notifies :restart, 'service[filtermail]', :delayed
end

template '/usr/local/etc/rc.d/filtermail-incoming' do
  owner 0
  group 0
  mode '0555'
  variables(
    execpath: '/usr/local/bin/filtermail',
    config_path: config_path
  )
  notifies :restart, 'service[filtermail-incoming]', :delayed
end

template '/usr/local/etc/rc.d/lastlogin' do
  owner 0
  group 0
  mode '0555'
  variables(
    execpath: chatmail_bin + '/lastlogin',
    config_path: config_path
  )
  notifies :restart, 'service[lastlogin]', :delayed
end
