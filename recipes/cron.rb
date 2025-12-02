#
# Cookbook:: chatmail
# Recipe:: cron
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package 'cron'

service 'cron.service' do
  action [:enable, :start]
end
