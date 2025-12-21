#
# Cookbook:: chatmail
# Recipe:: vmail_user
#
# Copyright:: 2023, The Authors, All Rights Reserved.

vmail_home = node['chatmail']['vmail_home']

# On FreeBSD, create a dedicated ZFS filesystem for mail storage before creating the user
if platform?('freebsd') && node['freebsd']['zfs']['enable']
  dataset = node['freebsd']['zfs']['vmail_dataset']
  quota = node['freebsd']['zfs']['vmail_quota']

  execute 'zfs create vmail storage' do
    command "zfs create -o compression=on -o mountpoint=#{vmail_home} #{dataset}"
    not_if "zfs list #{dataset} 2>/dev/null"
  end

  execute 'zfs set quota' do
    command "zfs set quota=#{quota} #{dataset}"
    not_if "zfs get -H -o value quota #{dataset} | grep #{quota}"
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
