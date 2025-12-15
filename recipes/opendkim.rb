#
# Cookbook:: chatmail
# Recipe:: opendkim
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_etc = node['etcdir']
service_name = node['opendkim']['service']
opendkim_user = node['opendkim']['user']
opendkim_group = node['opendkim']['group']
selector = node['chatmail']['dkim_selector']
opendkim_config_dir = node['opendkim']['config_dir']
config_file = "#{opendkim_config_dir}/opendkim.conf"
dkim_keys_dir = "#{platform_etc}/dkimkeys"

key_file_path = "#{dkim_keys_dir}/#{selector}.private"
key_table_path = "#{dkim_keys_dir}/KeyTable"
signing_table_path = "#{dkim_keys_dir}/SigningTable"
screen_policy_script_path = "#{opendkim_config_dir}/screen.lua"
final_policy_script_path = "#{opendkim_config_dir}/final.lua"
pidfile = node['opendkim']['pidfile']
trust_anchor_path = node['unbound']['trust_anchor']

directory dkim_keys_dir do
  owner opendkim_user
  group opendkim_group
  mode '0700'
  notifies :restart, "service[#{service_name}]", :delayed
end

directory opendkim_config_dir do
  owner opendkim_user
  group opendkim_group
  mode '0750'
  notifies :restart, "service[#{service_name}]", :delayed
end

cookbook_file "#{opendkim_config_dir}/screen.lua" do
  owner 0
  group 0
  mode '0644'
  notifies :restart, "service[#{service_name}]", :delayed
end

cookbook_file "#{opendkim_config_dir}/final.lua" do
  owner 0
  group 0
  mode '0644'
  notifies :restart, "service[#{service_name}]", :delayed
end

template "#{dkim_keys_dir}/KeyTable" do
  owner opendkim_user
  group opendkim_group
  mode '0644'
  variables({ 'domain' => node['chatmail']['domain'], 'dkim_selector' => selector, 'etcdir' => platform_etc })
  notifies :restart, "service[#{service_name}]", :delayed
end

template "#{dkim_keys_dir}/SigningTable" do
  owner opendkim_user
  group opendkim_group
  mode '0644'
  variables({ 'domain' => node['chatmail']['domain'], 'dkim_selector' => selector })
  notifies :restart, "service[#{service_name}]", :delayed
end

execute 'Generate OpenDKIM domain keys' do
  command "opendkim-genkey -D #{dkim_keys_dir} -d #{node['chatmail']['domain']} -s #{selector}"
  not_if { ::File.exist?(key_file_path.to_s) }
  notifies :restart, "service[#{service_name}]", :delayed
end

[key_file_path, "#{dkim_keys_dir}/#{selector}.txt"].each do |x|
  file x do
    owner opendkim_user
    group opendkim_group
    mode '600'
    notifies :restart, "service[#{service_name}]", :delayed
  end
end

template config_file do
  owner 0
  group 0
  mode '0644'
  variables(
    'domain' => node['chatmail']['domain'],
    'dkim_selector' => selector,
    'key_file_path' => key_file_path,
    'key_table_path' => key_table_path,
    'signing_table_path' => signing_table_path,
    'screen_policy_script_path' => screen_policy_script_path,
    'final_policy_script_path' => final_policy_script_path,
    'user_id' => opendkim_user,
    'trust_anchor_path' => trust_anchor_path,
    'pidfile' => pidfile
  )
  notifies :restart, "service[#{service_name}]", :delayed
end

service service_name do
  action [:enable, :start]
end

if platform_family?('debian')
  directory '/etc/systemd/system/opendkim.service.d'

  file '/etc/systemd/system/opendkim.service.d/10-prevent-memory-leak.conf' do
    owner 0
    group 0
    mode '0644'
    content <<~EOU
    [Service]
    Restart=always
    RuntimeMaxSec=1d
    EOU
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :restart, "service[#{service_name}]", :delayed
  end

  execute 'systemctl daemon-reload' do
    action :nothing
  end
end
