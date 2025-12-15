if platform?('freebsd')
  default['etcdir'] = '/usr/local/etc'
  default['wwwdir'] = '/usr/local/www'
  default['bindir'] = '/usr/local/bin'
  default['lego']['bin'] = '/usr/local/bin/lego'
  default['lego']['path'] = "#{node['etcdir']}/lego"
  default['chatmail']['certificates_dir'] = "#{node['etcdir']}/lego/certificates"
  default['virtualenv'] = '/usr/local/bin/virtualenv'
  default['chatmail']['python_version_string'] = '3.11'
  default['chatmail']['packages'] = %w( lang/python3
                                        lang/python
                                        devel/py-virtualenv
                                        databases/py-sqlite3
                                        deltachat-rpc-server
                                        dovecot
                                        mail/opendkim-devel
                                        postfix
                                        iroh-relay
                                        mtail
                                        nginx
                                        fcgiwrap
                                        chatmail-turn
                                        lowdown
                                        graphics/py-qrencode
                                        unbound
                                        lego
)
  default['chatmail']['metadata_sock'] = '/var/run/chatmail_metadata/metadata.sock'
  default['chatmail']['lastlogin_sock'] = '/var/run/lastlogin/lastlogin.sock'
  default['chatmail']['doveauth_sock'] = '/var/run/doveauth/doveauth.sock'
  default['fcgiwrap_sock'] = '/var/run/fcgiwrap/fcgiwrap.sock'
  default['stream_module_path'] = '/usr/local/libexec/nginx/ngx_stream_module.so'
  default['nginx_user'] = 'www'
  default['nginx_pidfile'] = '/var/run/nginx.pid'
  default['opendkim']['service'] = 'milter-opendkim'
  default['opendkim']['user'] = 'mailnull'
  default['opendkim']['group'] = 'mail'
  default['opendkim']['config_dir'] = lazy { "#{node['etcdir']}/mail" }
  default['opendkim']['pidfile'] = '/var/run/milteropendkim/pid'
  default['chatmail']['turnservice'] = 'chatmail_turn'
  default['unbound']['trust_anchor'] = lazy { "#{node['etcdir']}/unbound/root.key" }
  default['unbound']['anchor_bin'] = '/usr/local/sbin/unbound-anchor'
  default['unbound']['config_dir'] = lazy { "#{node['etcdir']}/unbound" }
  default['unbound']['config_file'] = lazy { "#{node['unbound']['config_dir']}/unbound.conf" }
end
