#
# Cookbook:: chatmail
# Recipe:: iroh
#
# Copyright:: 2023, The Authors, All Rights Reserved.

iroh_relay_path = '/usr/local/bin/iroh-relay'

group 'iroh'

user 'iroh' do
  gid 'iroh'
  home '/home/iroh'
  shell '/usr/sbin/nologin'
end

directory '/usr/local/bin'

# Handle based on platform
if platform_family?('freebsd')
  # Determine FreeBSD-specific paths
  platform_etc = node['etcdir']

  # Set up the configuration file
  cookbook_file "#{platform_etc}/iroh-relay.toml" do
    owner 0
    group 0
    mode '0644'
    notifies :restart, 'service[iroh-relay]', :delayed
  end
else
  # On Linux, continue with the download approach
  iroh_release = 'v0.35.0'
  iroh_tarball = "iroh-relay-#{iroh_release}-x86_64-unknown-linux-musl.tar.gz"
  iroh_relay_hash = '4103e64c5cd1fb94e8b11df0b9c572a38d44c6fd3cc174b921c806e7a183aadf'
  platform_etc = node['etcdir']

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
    notifies :restart, 'service[iroh-relay.service]', :delayed
  end

  execute 'extract iroh_relay' do
    command "tar xzf /tmp/#{iroh_tarball} -C /usr/local/bin"
    action :nothing
    notifies :restart, 'service[iroh-relay.service]', :delayed
  end

  file iroh_relay_path do
    owner 0
    group 0
    mode '0755'
    notifies :restart, 'service[iroh-relay.service]', :delayed
  end

  cookbook_file "#{platform_etc}/iroh-relay.toml" do
    owner 0
    group 0
    mode '0644'
    notifies :restart, 'service[iroh-relay.service]', :delayed
  end

  cookbook_file '/etc/systemd/system/iroh-relay.service' do
    owner 0
    group 0
    mode '0644'
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :restart, 'service[iroh-relay.service]', :delayed
  end

  execute 'systemctl daemon-reload' do
    action :nothing
  end
end

service 'iroh-relay' do
  action :enable
  only_if { node['chatmail']['iroh_relay'] }
end
