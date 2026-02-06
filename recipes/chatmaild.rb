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
githash = node['chatmaild']['githash']
venv_dir = node['chatmail']['venv_dir']

directory chatmail_root + '/dist' do
  recursive true
end

if platform_family?('freebsd')
  # Copy the FreeBSD patch first (before tarball)
  cookbook_file chatmail_root + '/dist/chatmaild.patch' do
    source 'freebsd/chatmaild.patch'
    owner 0
    group 0
    mode '0644'
    action :create
  end
end

cookbook_file chatmail_root + "/dist/chatmaild-#{release}-#{githash}.tar.gz" do
  owner 0
  group 0
  mode '0644'
  action :create
  notifies :run, 'execute[remove old chatmaild]', :immediately
end

execute 'remove old chatmaild' do
  command "rm -rf #{venv_dir}"
  action :nothing
  subscribes :run, "cookbook_file[#{chatmail_root}/dist/chatmaild.patch]", :delayed if platform_family?('freebsd')
  notifies :run, 'execute[virtualenv]', :immediately
end

execute 'virtualenv' do
  command <<~EOF
    #{virtualenv_cmd} #{venv_dir}
  EOF
  action :nothing
  notifies :run, 'execute[install chatmaild]', :immediately
end

if platform_family?('freebsd')

  # FreeBSD install: extract, patch, and install
  execute 'install chatmaild' do
    environment({ 'VIRTUAL_ENV' => venv_dir })
    command <<~EOF
      cd #{chatmail_root}/dist
      rm -rf chatmaild-#{release}
      tar -xzf chatmaild-#{release}-#{githash}.tar.gz
      cd chatmaild-#{release}
      patch -p2 < /usr/local/lib/chatmaild/dist/chatmaild.patch
      #{chatmail_bin}/pip install .
    EOF
    action :nothing
    notifies :restart, 'service[doveauth]', :delayed
    notifies :restart, 'service[chatmail-metadata]', :delayed
    notifies :restart, 'service[filtermail]', :delayed
    notifies :restart, 'service[filtermail-incoming]', :delayed
    notifies :restart, 'service[lastlogin]', :delayed
  end
else
  # Standard install for non-FreeBSD platforms
  execute 'install chatmaild' do
    environment({ 'VIRTUAL_ENV' => venv_dir })
    command <<~EOF
      #{chatmail_bin}/pip install #{chatmail_root}/dist/chatmaild-#{release}-#{githash}.tar.gz
    EOF
    action :nothing
    notifies :restart, 'service[doveauth]', :delayed
    notifies :restart, 'service[chatmail-metadata]', :delayed
    notifies :restart, 'service[filtermail]', :delayed
    notifies :restart, 'service[filtermail-incoming]', :delayed
    notifies :restart, 'service[lastlogin]', :delayed
  end

  # Install standalone filtermail binary on Debian
  filtermail_binary node['filtermail']['release'] do
    install_path node['filtermail']['bin']
    action :install
    notifies :restart, 'service[filtermail]', :delayed
    notifies :restart, 'service[filtermail-incoming]', :delayed
  end
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

%w(chatmail-metadata doveauth filtermail filtermail-incoming lastlogin).each do |s|
  service s do
    action :enable
  end
end

nocreate_action = if node['chatmail']['disable_registration']
                    :create
                  else
                    :delete
                  end

file "#{platform_etc}/chatmail-nocreate" do
  action nocreate_action
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
