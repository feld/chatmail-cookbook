#
# Cookbook:: chatmail
# Recipe:: cron
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package 'cron'

service 'cron.service' do
  action [:enable, :start]
end

template '/etc/cron.d/expunge' do
  source 'expunge.cron.erb'
  owner 0
  group 0
  mode '0644'
  variables({ 'config' => node['chatmail'] })
end
