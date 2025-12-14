#
# Cookbook:: chatmail
# Recipe:: packages
#
# Copyright:: 2023, The Authors, All Rights Reserved.

if platform?('debian')
  package 'gpg'

  cookbook_file '/etc/apt/keyrings/obs-home-deltachat.gpg' do
    owner 0
    group 0
    mode '0444'
  end

  # Custom pkg repo required for patched Dovecot
  apt_repository 'DeltaChat_OBS' do
    components ['./']
    distribution ''
    uri 'https://download.opensuse.org/repositories/home:/deltachat/Debian_12/'
    options ['signed-by=/etc/apt/keyrings/obs-home-deltachat.gpg']
    action :add
  end
end

if platform?('freebsd')
  # Custom pkg repo required for patched Dovecot, mtail, chatmail-turn, and iroh-relay
  pkg_repository 'chatmail' do
    priority 10
    url 'http://pkg.radiks.org/${ABI}-chatmail'
  end

  # Disable the FreeBSD-ports package repo due
  # to it using the quarterly branch by default
  # which can have older packages and cause library
  # conclicts. e.g., install git on a new server,
  # try to deploy chatmail, Nginx installs but with
  # the wrong pcre2 library
  file '/usr/local/etc/pkg/repos/FreeBSD-ports.conf' do
    owner 0
    group 0
    mode '0644'
    content 'FreeBSD-base: { enabled: no }'
    notifies :run, 'execute[pkg ugprade]', :immediately
  end

  # Upgrade what we can to the Chatmail repo's packages
  execute 'pkg upgrade' do
    command 'pkg upgrade -y'
    action :nothing
  end
end

# Install packages only - this ensures users/groups exist for service configuration
node['chatmail']['packages'].each do |i|
  if platform_family?('freebsd')
    package i do
      repository 'chatmail'
    end
  else
    package i
  end
end
