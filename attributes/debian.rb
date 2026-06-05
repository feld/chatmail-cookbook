if platform?('debian')
  default['etcdir'] = '/etc'
  default['wwwdir'] = '/var/www'
  default['bindir'] = '/usr/bin'
  default['syslog_sock'] = '/dev/log'
  default['lego']['bin'] = '/usr/bin/lego'
  default['lego']['path'] = lazy { "#{node['etcdir']}/lego" }
  default['filtermail']['bin'] = '/usr/local/bin/filtermail'
  default['chatmail']['certificates_dir'] = lazy { "#{node['lego']['path']}/certificates" }
  default['virtualenv'] = '/usr/bin/virtualenv'
  default['chatmail']['packages'] = %w( python3-virtualenv
                                        postfix
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
    'aarch64' => '6833061b2a2028264fdeb32f0a6123e1ff73de57dace125364016300b748452e',
  }

  default['dovecot']['archive_version'] = '2.3.21+dfsg1-3'
  case node['platform_version'].to_i
  when 12
    default['dovecot']['checksums']['core'] = {
      'x86_64' => 'd631fe5ec5574d2d38e889b141cf8ffaab1e949fb2af306669584c3e37e37cc8',
      'aarch64' => '658813382a86aac6d92179fd1bb78454139211e09dda150a43e177a60d838ece',
    }
    default['dovecot']['checksums']['imapd'] = {
      'x86_64' => '834d014e8a91989f19b276cde9ae932cbda0c5461e89b506ab37ef31681e0c53',
      'aarch64' => 'ddf4cb5db3f3f557edd9579cd5652f59201ac34009a12c92129a10b3f959ef6f',
    }
    default['dovecot']['checksums']['lmtpd'] = {
      'x86_64' => '12ebaa88ccfd46e63f0f0496cf180eb8c01cbd3b16f98d8ac2bc02cdcc033036',
      'aarch64' => 'faf50c04f202093d7de621b4b85210c41b4e5550deed1ddbcf5830c7d4d6ca76',
    }

  when 13
    default['dovecot']['checksums']['core'] = {
      'x86_64' => '65834713de5e4b27d035b0307b008bad922e3b3375c285d66bb0e3c81130c015',
      'aarch64' => 'xxx',
    }
    default['dovecot']['checksums']['imapd'] = {
      'x86_64' => 'fddb77c2669ab3ba6eb18f2525b129cef527c1b8b52f6018e7d25d06f1f325ec',
      'aarch64' => 'xxx',
    }
    default['dovecot']['checksums']['lmtpd'] = {
      'x86_64' => '58d91a235b939008c22a715e4938515c598f2b496e8525581bce731bfb70aaed',
      'aarch64' => 'xxx',
    }
  end
end
