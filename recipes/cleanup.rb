#
# Cookbook:: chatmail
# Recipe:: cleanup
#
# Copyright:: 2023, The Authors, All Rights Reserved.

oldpackages = node['chatmail']['oldpackages']
oldservices = node['chatmail']['oldservices']
oldfiles = node['chatmail']['oldfiles']
olddirs = node['chatmail']['olddirs']
oldusers = node['chatmail']['oldusers']

oldpackages.each do |x|
  package x do
    action :remove
    ignore_failure true
  end
end

oldservices.each do |x|
  service x do
    action [:stop, :disable]
  end
end

oldfiles.each do |x|
  file x do
    action :delete
  end
end

olddirs.each do |x|
  directory x do
    action :delete
    recursive true
  end
end

oldusers.each do |x|
  user x do
    action :remove
  end
end

# Just in case on Debian
if platform_family?('debian')
  execute 'systemctl daemon-reload'
end

# Used crontab, was problematic parsing
# for some lego ENVs
cron 'lego_renewal' do
  action :delete
end

# Clean up possibly old log files that were rotated but should not have been
execute 'rm -f /var/log/maillog*bz2 /var/log/messages*bz2 /var/log/daemon.log*bz2' do
  only_if { platform_family?('freebsd') }
end
