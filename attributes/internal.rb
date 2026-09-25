# Things that are technically configurable
# but don't need to be customized per OS
# Usually these don't need to change
default['chatmaild']['release'] = '0.3'
default['chatmaild']['githash'] = 'aa846c3478fed5cee14ce8e7b68775f2a9a22dc1'
default['chatmail']['cgi-bin'] = '/usr/lib/cgi-bin'
default['chatmail']['base_dir'] = '/usr/local/lib/chatmaild'
default['chatmail']['venv_dir'] = lazy { "#{node['chatmail']['base_dir']}/venv" }
default['chatmail']['bin_dir'] = lazy { "#{node['chatmail']['venv_dir']}/bin" }
default['chatmail']['config_path'] = lazy { "#{node['chatmail']['base_dir']}/chatmail.ini" }
default['chatmail']['vmail_home'] = '/home/vmail'
default['chatmail']['mailboxes_dir'] = lazy { "#{node['chatmail']['vmail_home']}/mail/#{node['chatmail']['domain']}" }
default['filtermail']['smtp_port'] = '10080'
default['filtermail']['smtp_port_incoming'] = '10081'
default['filtermail']['http_port_incoming'] = '10082'
default['postfix']['reinject_port'] = '10025'
default['postfix']['reinject_port_incoming'] = '10026'
default['lego']['release'] = 'v5.2.2'
