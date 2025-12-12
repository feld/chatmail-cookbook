#
# Cookbook:: chatmail
# Recipe:: systemd
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Reset failed services just in case
if platform_family?('debian')
  execute 'systemctl reset-failed' do
    only_if "systemctl is-failed -q '*'"
  end
end
