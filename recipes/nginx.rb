#
# Cookbook:: chatmail
# Recipe:: nginx
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_etc = node['etcdir']
platform_www = node['wwwdir'] + '/html'
fcgiwrap_sock = node['fcgiwrap_sock']
stream_module_path = node['stream_module_path']
nginx_user = node['nginx_user']
nginx_config_dir = platform_etc + '/nginx'
pid_file = node['nginx_pidfile']

template "#{platform_etc}/nginx/nginx.conf" do
  owner 0
  group 0
  mode '0644'
  variables(
    'config' => node['chatmail'],
    'stream_module_path' => stream_module_path,
    'nginx_user' => nginx_user,
    'nginx_config_dir' => nginx_config_dir,
    'pid_file' => pid_file,
    'platform_www' => platform_www,
    'fcgiwrap_sock' => fcgiwrap_sock
  )
  notifies :restart, 'service[nginx]', :delayed
end

service 'nginx' do
  action [:enable, :start]
end

if platform_family?('freebsd')
  # This hack because setting vars in /etc/rc.conf
  # is ugly, haven't imported the custom Chef resource
  # for it, and FreeBSD rc does not play nice if
  # enable is in one file and the extra options in
  # another...
  file '/etc/rc.conf.d/fcgiwrap' do
    content content <<~EOU
fcgiwrap_enable="YES"
fcgiwrap_socket_owner="#{nginx_user}"
EOU
    mode '0644'
    owner 0
    group 0
  end
end

if platform_family?('debian')
  service 'fcgiwrap.socket' do
    action [:enable, :start]
  end
end

service 'fcgiwrap' do
  action [:enable, :start]
end

directory "#{platform_www}/.well-known/autoconfig/mail" do
  recursive true
end

template "#{platform_www}/.well-known/mta-sts.txt" do
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
end

template "#{platform_www}/.well-known/autoconfig/mail/config-v1.1.xml" do
  owner 0
  group 0
  source 'autoconfig.xml.erb'
  mode '0644'
  variables({ 'config' => node['chatmail'] })
end
