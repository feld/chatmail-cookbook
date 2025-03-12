#
# Cookbook:: chatmail
# Recipe:: iroh
#
# Copyright:: 2023, The Authors, All Rights Reserved.

iroh_release = 'v0.28.1'
iroh_tarball = "iroh-relay-#{iroh_release}-x86_64-unknown-linux-musl.tar.gz"
iroh_relay_hash = '2ffacf7c0622c26b67a5895ee8e07388769599f60e5f52a3bd40a3258db89b2c'
iroh_relay_path = '/usr/local/bin/iroh-relay'

group 'iroh'

user 'iroh' do
  gid 'iroh'
  home '/home/iroh'
  shell '/usr/sbin/nologin'
end

directory '/usr/local/bin'

remote_file "/tmp/#{iroh_tarball}" do
  source "https://github.com/n0-computer/iroh/releases/download/#{iroh_release}/iroh-relay-#{iroh_release}-x86_64-unknown-linux-musl.tar.gz"
  mode '0644'
  action :create
  # Only download if checksum doesn't match
  not_if do
    ::File.exist?(iroh_relay_path) && \
      ::Digest::SHA256.file(iroh_relay_path).hexdigest == iroh_relay_hash
  end
  notifies :run, 'execute[extract iroh_relay]', :immediately
end

execute 'extract iroh_relay' do
  command "tar xzf /tmp/#{iroh_tarball} -C /usr/local/bin"
  action :nothing
end

file iroh_relay_path do
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/etc/iroh-relay.toml' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[iroh-relay.service]', :delayed
end

cookbook_file '/etc/systemd/system/iroh-relay.service' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[iroh-relay.service]', :delayed
end

service 'iroh-relay.service' do
  action [:enable, :start]
end

execute 'systemctl daemon-reload' do
  action :nothing
end
