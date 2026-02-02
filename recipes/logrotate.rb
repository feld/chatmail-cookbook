#
# Cookbook:: chatmail
# Recipe:: logrotate (FreeBSD newsyslog)
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Configure newsyslog for FreeBSD log retention (similar to journald retention on Linux)
if platform_family?('freebsd')
  directory '/etc/newsyslog.conf.d' do
    owner 0
    group 0
    mode '0755'
    action :create
  end

  template '/etc/newsyslog.conf' do
    owner 0
    group 0
    mode '0644'
    source 'freebsd/newsyslog.conf.erb'
    variables({ 'config' => node['chatmail'] })
  end

  execute 'newsyslog -CC' do
    action :nothing
    subscribes :run, 'template[/etc/newsyslog.conf]', :immediately
  end
end
