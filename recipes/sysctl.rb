#
# Cookbook:: chatmail
# Recipe:: sysctl
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Linux inotify settings
if platform_family?('debian')
  file '/etc/sysctl.conf' do
    action :create_if_missing
    owner 0
    group 0
    mode '0644'
  end

  inotify_sysctls = %w(max_user_instances max_user_watches)

  inotify_sysctls.each do |s|
    sysctl "fs.inotify.#{s}" do
      value '65535'
    end
  end
end

if platform_family?('freebsd')
  jailed = `sysctl -n security.jail.jailed `.strip!

  # In a jail we cannot set this
  if jailed == '0'
    freebsd_sysctl 'net.inet6.ip6.v6only' do
      value '0'
      action :set
      notifies :restart, 'service[iroh-relay]', :delayed
    end

    # Otherwise binds to tcp6 only
    service 'iroh-relay' do
      action :nothing
    end
  end
end
