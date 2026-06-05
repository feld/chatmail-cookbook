if platform?('debian')
  default['etcdir'] = '/etc'
  default['wwwdir'] = '/var/www'
  default['bindir'] = '/usr/bin'
  default['syslog_sock'] = '/dev/log'
  default['lego']['bin'] = '/usr/bin/lego'
  default['lego']['path'] = lazy { "#{node['etcdir']}/lego" }
  default['filtermail']['bin'] = '/usr/local/bin/filtermail'
  default['chatmail']['python_version_string'] = '3.11'
  default['chatmail']['certificates_dir'] = lazy { "#{node['lego']['path']}/certificates" }
  default['virtualenv'] = '/usr/bin/virtualenv'
  default['chatmail']['packages'] = %w( python3-virtualenv
                                        postfix
                                        dovecot-imapd
                                        dovecot-lmtpd
                                        opendkim
                                        opendkim-tools
                                        cron
                                        mtail
                                        nginx
                                        libnginx-mod-stream
                                        fcgiwrap
                                        lowdown
                                        qrencode
                                        unbound
                                        dnsutils
)
  default['chatmail']['metadata_sock'] = '/run/chatmail-metadata/metadata.socket'
  default['chatmail']['lastlogin_sock'] = '/run/chatmail-lastlogin/lastlogin.socket'
  default['chatmail']['doveauth_sock'] = '/run/doveauth/doveauth.socket'
  default['chatmail']['turn_sock'] = '/run/chatmail-turn/turn.socket'
  default['fcgiwrap_sock'] = '/run/fcgiwrap.socket'
  default['stream_module_path'] = 'modules/ngx_stream_module.so'
  default['nginx_user'] = 'www-data'
  default['nginx_pidfile'] = '/run/nginx.pid'
  default['opendkim']['service'] = 'opendkim'
  default['opendkim']['user'] = 'opendkim'
  default['opendkim']['group'] = 'opendkim'
  default['opendkim']['config_dir'] = lazy { "#{node['etcdir']}/opendkim" }
  default['opendkim']['config_file'] = lazy { "#{node['etcdir']}/opendkim.conf" }
  default['opendkim']['pidfile'] = '/run/opendkim/opendkim.pid'
  default['opendkim']['genkey_bin'] = '/usr/sbin/opendkim-genkey'
  default['chatmail']['turnservice'] = 'turnserver'
  default['unbound']['trust_anchor'] = '/usr/share/dns/root.key'
  default['unbound']['anchor_bin'] = '/sbin/unbound-anchor'
  default['unbound']['config_dir'] = lazy { "#{node['etcdir']}/unbound" }
  default['unbound']['config_file'] = lazy { "#{node['unbound']['config_dir']}/unbound.conf.d/unbound.conf" }
  default['filtermail']['release'] = 'v0.7.0'
  default['filtermail']['checksums'] = {
    'x86_64' => '451f295a85b3b12dbb0f89e18ec319f742ee46dec218f20f7923bfb017a248bd',
    'aarch64' => '6833061b2a2028264fdeb32f0a6123e1ff73de57dace125364016300b748452e'
}
end
