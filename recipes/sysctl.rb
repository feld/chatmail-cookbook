#
# Cookbook:: chatmail
# Recipe:: sysctl
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Linux inotify settings
if platform_family?('debian')
  inotify_sysctls = %w(max_user_instances max_user_watches)

  inotify_sysctls.each do |s|
    sysctl "fs.inotify.#{s}" do
      value '65535'
    end
  end
end

# FreeBSD specific settings can be added here if needed
