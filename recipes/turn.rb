#
# Cookbook:: chatmail
# Recipe:: turn
#
# Copyright:: 2023, The Authors, All Rights Reserved.

service_name = node['chatmail']['turnservice']
turn_path = '/usr/local/bin/chatmail-turn'

if platform_family?('debian')
  turn_url = 'https://github.com/chatmail/chatmail-turn/releases/download/v0.3/chatmail-turn-x86_64-linux'
  turn_hash = '841e527c15fdc2940b0469e206188ea8f0af48533be12ecb8098520f813d41e4'

  directory '/usr/local/bin'

  remote_file turn_path do
    source turn_url
    mode '0755'
    owner 0
    group 0
    action :create
    # Only download if checksum doesn't match
    not_if do
      ::File.exist?(turn_path) && \
        ::Digest::SHA256.file(turn_path).hexdigest == turn_hash
    end
    notifies :restart, "service[#{service_name}]", :delayed
  end

  template '/etc/systemd/system/turnserver.service' do
    owner 'root'
    group 'root'
    mode '0644'
    variables({ 'config' => node['chatmail'] })
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :restart, "service[#{service_name}]", :delayed
  end

  execute 'systemctl daemon-reload' do
    action :nothing
  end
end

service service_name do
  action :enable
end
