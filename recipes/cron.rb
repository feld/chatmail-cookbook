#
# Cookbook:: chatmail
# Recipe:: cron
#
# Copyright:: 2023, The Authors, All Rights Reserved.

service 'cron' do
  action [:enable, :start]
end
