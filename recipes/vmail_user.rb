#
# Cookbook:: chatmail
# Recipe:: vmail_user
#
# Copyright:: 2023, The Authors, All Rights Reserved.

vmail_home = '/home/vmail'

# On FreeBSD, create a dedicated ZFS filesystem for mail storage before creating the user
if platform?('freebsd')
  vmail_zfs_dataset = node['zfs']['vmail_dataset']

  execute 'zfs create vmail storage' do
    command "zfs create -o compression=on -o mountpoint=#{vmail_home} #{vmail_zfs_dataset}"
    not_if 'zfs list zroot/home/vmail 2>/dev/null'
  end

  execute 'zfs set quota' do
    command "zfs set quota=#{node['zfs']['vmail_quota']} #{vmail_zfs_dataset}"
    not_if "zfs get -H -o value quota #{vmail_zfs_dataset} | grep -x '#{node['zfs']['vmail_quota']}'"
  end
end

group 'vmail' do
  action :create
end

user 'vmail' do
  gid 'vmail'
  home vmail_home
  manage_home true
  shell '/bin/sh'
end
