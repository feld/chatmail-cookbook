#
# Cookbook:: chatmail
# Recipe:: chatmaild
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_etc = node['etcdir']
node['lego']['bin']
virtualenv_cmd = node['virtualenv']

chatmail_bin = node['chatmail']['bin_dir']
config_path = node['chatmail']['config_path']
chatmail_root = node['chatmail']['base_dir']
release = node['chatmaild']['release']
venv_dir = node['chatmail']['venv_dir']

directory chatmail_root + '/dist' do
  recursive true
end

cookbook_file chatmail_root + "/dist/chatmaild-#{release}.tar.gz" do
  owner 0
  group 0
  mode '0644'
  action :create
  notifies :run, 'execute[remove old chatmaild]', :immediately
  notifies :run, 'execute[virtualenv]', :immediately
  notifies :run, 'execute[install chatmaild]', :immediately
end

execute 'remove old chatmaild' do
  command "rm -rf #{venv_dir}"
  action :nothing
end

execute 'virtualenv' do
  command <<~EOF
    #{virtualenv_cmd} #{venv_dir}
  EOF
  action :nothing
end

execute 'install chatmaild' do
  environment({ 'VIRTUAL_ENV' => venv_dir })
  command <<~EOF
    #{chatmail_bin}/pip install #{chatmail_root}/dist/chatmaild-#{release}.tar.gz
  EOF
  action :nothing
  notifies :restart, 'service[doveauth]', :delayed
  notifies :restart, 'service[chatmail-metadata]', :delayed
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
  notifies :restart, 'service[filtermail]', :delayed
  notifies :restart, 'service[filtermail-incoming]', :delayed
  notifies :restart, 'service[lastlogin]', :delayed
end

if platform_family?('freebsd')
  include_recipe 'chatmail::_chatmaild_freebsd'
end

if platform_family?('debian')
  include_recipe 'chatmail::_chatmaild_debian'
end

service 'chatmail-metadata' do
  action [:enable, :start]
end

service 'doveauth' do
  action [:enable, :start]
end

service 'filtermail' do
  action [:enable, :start]
end

service 'filtermail' do
  action [:enable, :start]
end

service 'filtermail-incoming' do
  action [:enable, :start]
end

service 'lastlogin' do
  action [:enable, :start]
end

nocreate_action = if node['chatmail']['disable_registration']
                    :create
                  else
                    :delete
                  end

file "#{platform_etc}/chatmail-nocreate" do
  action nocreate_action
end

template '/etc/cron.d/chatmail' do
  source 'chatmail.cron.erb'
  owner 0
  group 0
  mode '0644'
  variables({ 'chatmail_bin' => chatmail_bin, 'config_file' => config_path, 'config' => node['chatmail'] })
end

cgi_bin_path = node['chatmail']['cgi-bin']

directory cgi_bin_path do
  recursive true
end

pyver = node['chatmail']['python_version_string']

remote_file "#{cgi_bin_path}/newemail.py" do
  source "file://#{venv_dir}/lib/python#{pyver}/site-packages/chatmaild/newemail.py"
  owner 0
  group 0
  mode '0555'
end
