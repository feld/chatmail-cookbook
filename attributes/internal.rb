# Things that are technically configurable
# but don't need to be customized per OS
# Usually these don't need to change
default['chatmaild']['release'] = '0.3'
default['chatmaild']['githash'] = 'a47bb941434d6b7c222c20de2921ac38956c8f1e'
default['chatmail']['cgi-bin'] = '/usr/lib/cgi-bin'
default['chatmail']['base_dir'] = '/usr/local/lib/chatmaild'
default['chatmail']['venv_dir'] = lazy { "#{node['chatmail']['base_dir']}/venv" }
default['chatmail']['bin_dir'] = lazy { "#{node['chatmail']['venv_dir']}/bin" }
default['chatmail']['config_path'] = lazy { "#{node['chatmail']['base_dir']}/chatmail.ini" }
default['chatmail']['vmail_home'] = '/home/vmail'
default['filtermail']['http_port_incoming'] = '10082'
