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
syslog_sock = node['syslog_sock']

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
    'fcgiwrap_sock' => fcgiwrap_sock,
    'syslog_sock' => syslog_sock
  )
  notifies :restart, 'service[nginx]', :delayed
end

service 'nginx' do
  action :enable
end

if platform_family?('freebsd')
  execute 'configuring fcgiwrap' do
    command "sysrc fcgiwrap_socket_owner=\"#{nginx_user}\""
    not_if "sysrc -c fcgiwrap_socket_owner=\"#{nginx_user}\""
    notifies :restart, 'service[fcgiwrap]', :delayed
  end
end

if platform_family?('debian')
  service 'fcgiwrap.socket' do
    action :enable
  end
end

service 'fcgiwrap' do
  action :enable
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
