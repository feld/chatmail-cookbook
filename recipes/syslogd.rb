#
# Cookbook:: chatmail
# Recipe:: syslogd
#
# Copyright:: 2023, The Authors, All Rights Reserved.

if platform_family?('freebsd')

  jailed = `sysctl -n security.jail.jailed `.strip!

  # In a jail we want to enable syslog, but not open any
  # sockets.
  if jailed == '1'
    execute 'configure syslog' do
      command 'sysrc syslogd_flags="-ss"'
      not_if 'sysrc -c syslogd_flags="-ss"'
      notifies :restart, 'service[syslogd]', :delayed
    end
  end

  service 'syslogd' do
    action [:enable, :start]
  end
end
