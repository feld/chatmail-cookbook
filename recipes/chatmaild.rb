#
# Cookbook:: chatmail
# Recipe:: chatmaild
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package %w(acl python3-virtualenv)

remote_base_dir = '/usr/local/lib/chatmaild'
remote_venv_dir = remote_base_dir + '/venv'
chatmail_bin = remote_venv_dir + '/bin'
config_path = remote_base_dir + '/chatmail.ini'
release = node['chatmaild']['release']

directory remote_base_dir + '/dist' do
  recursive true
end

cookbook_file remote_base_dir + "/dist/chatmaild-#{release}.tar.gz" do
  owner 0
  group 0
  mode '0644'
  action :create
  notifies :run, 'execute[remove old chatmaild]', :immediately
end

execute 'remove old chatmaild' do
  command "rm -rf #{remote_venv_dir}"
  action :nothing
end

execute 'virtualenv' do
  cwd Chef::Config[:file_cache_path]
  command <<~EOF
    /usr/bin/virtualenv #{remote_venv_dir}
  EOF
  not_if { Dir.exist?(remote_venv_dir) }
end

execute 'install chatmaild' do
  environment({ 'VIRTUAL_ENV' => remote_venv_dir })
  command <<~EOF
    #{chatmail_bin}/pip install #{remote_base_dir}/dist/chatmaild-#{release}.tar.gz
  EOF
  not_if { ::File.exist?(chatmail_bin + '/deltachat-rpc-server') }
  notifies :restart, 'service[doveauth]', :delayed
  notifies :restart, 'service[chatmail-metadata]', :delayed
  notifies :restart, 'service[echobot]', :delayed
  notifies :restart, 'service[filtermail]', :delayed
  notifies :restart, 'service[filtermail-incoming]', :delayed
  notifies :restart, 'service[lastlogin]', :delayed
end

template config_path do
  owner 0
  group 0
  source 'chatmail.ini.erb'
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :restart, 'service[doveauth]', :delayed
  notifies :restart, 'service[chatmail-metadata]', :delayed
  notifies :restart, 'service[echobot]', :delayed
  notifies :restart, 'service[filtermail]', :delayed
  notifies :restart, 'service[filtermail-incoming]', :delayed
  notifies :restart, 'service[lastlogin]', :delayed
end

execpath = chatmail_bin + '/doveauth'
template '/etc/systemd/system/doveauth.service' do
  source 'doveauth.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: execpath,
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[doveauth]', :delayed
end

service 'doveauth' do
  action [:enable, :start]
end

execpath = chatmail_bin + '/chatmail-metadata'
template '/etc/systemd/system/chatmail-metadata.service' do
  source 'chatmail-metadata.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: execpath,
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[chatmail-metadata]', :delayed
end

service 'chatmail-metadata' do
  action [:enable, :start]
end

group 'echobot' do
  notifies :restart, 'service[echobot]', :delayed
end

user 'echobot' do
  gid 'echobot'
  home '/home/echobot'
  shell '/bin/sh'
  notifies :restart, 'service[echobot]', :delayed
end

execpath = chatmail_bin + '/echobot'
template '/etc/systemd/system/echobot.service' do
  source 'echobot.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: execpath,
    config_path: config_path,
    remote_venv_dir: remote_venv_dir
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[echobot]', :delayed
end

service 'echobot' do
  action [:enable, :start]
end

group 'filtermail' do
  notifies :restart, 'service[filtermail]', :delayed
end

user 'filtermail' do
  gid 'filtermail'
  home '/home/filtermail'
  shell '/bin/sh'
  notifies :restart, 'service[filtermail]', :delayed
end

execpath = chatmail_bin + '/filtermail'
template '/etc/systemd/system/filtermail.service' do
  source 'filtermail.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: execpath,
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[filtermail]', :delayed
end

service 'filtermail' do
  action [:enable, :start]
end

template '/etc/systemd/system/filtermail-incoming.service' do
  source 'filtermail-incoming.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: execpath,
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[filtermail-incoming]', :delayed
end

service 'filtermail-incoming' do
  action [:enable, :start]
end

execpath = chatmail_bin + '/lastlogin'
template '/etc/systemd/system/lastlogin.service' do
  source 'lastlogin.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    execpath: execpath,
    config_path: config_path
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[lastlogin]', :delayed
end

service 'lastlogin' do
  action [:enable, :start]
end

execute 'systemctl daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

template '/etc/cron.d/chatmail-metrics' do
  source 'metrics.cron.erb'
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'], 'chatmail_bin' => chatmail_bin })
end

nocreate_action = if node['chatmail']['disable_registration']
                    :create
                  else
                    :delete
                  end

file '/etc/chatmail-nocreate' do
  action nocreate_action
end
