#
# Cookbook:: chatmail
# Recipe:: turn
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Only x86_64 for now

turn_release = 'v0.3'
turn_hash = '841e527c15fdc2940b0469e206188ea8f0af48533be12ecb8098520f813d41e4'
turn_path = '/usr/local/bin/chatmail-turn'

directory '/usr/local/bin'

remote_file turn_path do
  source "https://github.com/chatmail/chatmail-turn/releases/download/#{turn_release}/chatmail-turn-x86_64-linux"
  mode '0755'
  owner 0
  group 0
  action :create
  # Only download if checksum doesn't match
  not_if do
    ::File.exist?(turn_path) && \
      ::Digest::SHA256.file(turn_path).hexdigest == turn_hash
  end
  notifies :restart, 'service[turnserver.service]', :delayed
end

template '/etc/systemd/system/turnserver.service' do
  owner 'root'
  group 'root'
  mode '0644'
  variables({ 'config' => node['chatmail'] })
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[turnserver.service]', :delayed
end

service 'turnserver.service' do
  action [:enable, :start]
end

execute 'systemctl daemon-reload' do
  action :nothing
end
