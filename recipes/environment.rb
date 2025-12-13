#
# Cookbook:: chatmail
# Recipe:: environment
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Environment file is Linux-specific (systemd-related), so only create on Linux systems
if platform_family?('debian')
  file '/etc/environment' do
    owner 0
    group 0
    mode '0644'
    content <<~EOU
EDITOR=vi
SYSTEMD_LESS=FRXMK
TZ=:/etc/localtime
EOU
  end
end
