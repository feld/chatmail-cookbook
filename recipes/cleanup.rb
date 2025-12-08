#
# Cookbook:: chatmail
# Recipe:: cleanup
#
# Copyright:: 2023, The Authors, All Rights Reserved.

oldservices = %w(postfix-mta-sts-resolver.service)

oldservices.each do |x|
  service x do
    action [:stop, :disable]
  end
end

oldpackages = %w(postfix-mta-sts-resolver)

oldpackages.each do |x|
  package x do
    action :purge
  end
end

oldfiles = %w(/etc/mta-sts-daemon.yml /etc/cron.d/chatmail-metrics /etc/cron.d/expunge)

oldfiles.each do |x|
  file x do
    action :delete
  end
end

olddirs = %w(/usr/local/lib/postfix-mta-sts-resolver)

olddirs.each do |x|
  directory x do
    action :delete
    recursive true
  end
end

# Remove Echobot
service 'echobot' do
  action [:disable, :stop]
end

user 'echobot' do
  action :remove
end

file '/etc/systemd/system/echobot.service' do
  action :delete
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

execute 'systemctl daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end
