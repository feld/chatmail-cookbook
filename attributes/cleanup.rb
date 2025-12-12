if platform?('freebsd')
  default['chatmail']['oldpackages'] = %w( )
  default['chatmail']['oldservices'] = %w( )
end
if platform?('debian')
  default['chatmail']['oldpackages'] = %w( postfix-mta-sts-resolver )
  default['chatmail']['oldservices'] = %w( echobot postfix-mta-sts-resolver )
end

default['chatmail']['oldusers'] = %w( echobot )
default['chatmail']['oldfiles'] = [
  "#{node['etcdir']}/mta-sts-daemon.yml",
  '/etc/cron.d/chatmail-metrics',
  '/etc/cron.d/expunge',
  "#{node['wwwdir']}/html/metrics",
  '/etc/systemd/system/echobot.service',
]
default['chatmail']['olddirs'] = []
