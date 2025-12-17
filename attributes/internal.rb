# Things that are technically configurable
# but don't need to be customized per OS
# Usually these don't need to change
default['chatmaild']['release'] = '0.3-9bf99cc8a9fa97358ca63fc7e23531b482e0d610'
default['chatmail']['cgi-bin'] = '/usr/lib/cgi-bin'
default['chatmail']['base_dir'] = '/usr/local/lib/chatmaild'
default['chatmail']['venv_dir'] = lazy { "#{node['chatmail']['base_dir']}/venv" }
default['chatmail']['bin_dir'] = lazy { "#{node['chatmail']['venv_dir']}/bin" }
default['chatmail']['config_path'] = lazy { "#{node['chatmail']['base_dir']}/chatmail.ini" }
default['chatmail']['vmail_home'] = '/home/vmail'
