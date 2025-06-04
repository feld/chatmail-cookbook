#
# Cookbook:: chatmail
# Recipe:: sysctl
#
# Copyright:: 2023, The Authors, All Rights Reserved.

inotify_sysctls = %w(max_user_instances max_user_watches)

inotify_sysctls.each do |s|
  sysctl "#{s}" do
    value '65535'
  end
end
