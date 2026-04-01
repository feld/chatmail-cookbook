if platform?('freebsd')
  default['chatmail']['oldpackages'] = %w( iroh-relay deltachat-rpc-server )
  default['chatmail']['oldservices'] = %w( iroh-relay )
end
if platform?('debian')
  default['chatmail']['oldpackages'] = %w( postfix-mta-sts-resolver )
  default['chatmail']['oldservices'] = %w( echobot postfix-mta-sts-resolver iroh-relay )
end

default['chatmail']['oldusers'] = %w( echobot iroh )
default['chatmail']['oldfiles'] = [
  "#{node['etcdir']}/mta-sts-daemon.yml",
  '/etc/cron.d/chatmail-metrics',
  '/etc/cron.d/expunge',
  "#{node['wwwdir']}/html/metrics",
  '/etc/systemd/system/echobot.service',
  '/etc/newsyslog.conf.d/chatmail.conf',
  "#{node['etcdir']}/iroh-relay.toml",
  "/etc/systemd/system/iroh-relay.service",
]
default['chatmail']['olddirs'] = []
