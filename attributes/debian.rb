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


  # dovecot-core_2.3.21+dfsg1-3+chatmail2+deb12u1_amd64.deb
  # We will append the _arch.deb suffix in the recipe
  default['dovecot']['archive_version'] = "2.3.21+dfsg1-3+chatmail2+deb#{node['platform_version'].to_i}u1"
  case node['platform_version'].to_i
  when 12
    default['dovecot']['checksums']['core'] = {
      'x86_64' => 'ac3977264d9b9a6fcec53fd3f5cdd2a79ca8aa0324de530c07e535008540826e',
      'aarch64' => '21626c9c9b52cbdcf1a17b5c09e3c4043e69aa371bf83cc2fcb3b7ddaecdc109',
    }
    default['dovecot']['checksums']['imapd'] = {
      'x86_64' => '92a7ab5fc7dc32886a0c34404f919f1335d397b48c467e0c1ef77e56978f60ea',
      'aarch64' => '9369fd566fec4df109ef23debf34ea0417ae85beb29cbe7de619d4d1f31b120c',
    }
    default['dovecot']['checksums']['lmtpd'] = {
      'x86_64' => 'dc3de473789969f7dd3504ac8783da5e42a446d2d7a305a4e9d7081a6dfe71ab',
      'aarch64' => 'ae2cbd6c5c43f6d8e2172997b055448f4c79238e2f99cd9ab9200a7d9f548908',
    }

  when 13
    default['dovecot']['checksums']['core'] = {
      'x86_64' => '47c242ef23c17e700ac19d52d82c9fdb2ebd757d8beb3a7f6781d2de59f87bd0',
      'aarch64' => 'c14c53f112c875f698c4cb6e5870c605cd0a9dd98d35a66e94ceb1827f8020a3',
    }
    default['dovecot']['checksums']['imapd'] = {
      'x86_64' => 'e38cc1266455f937ed62f971ea859c47e1a99247841ed0ad946963b524cfdbc5',
      'aarch64' => '11d97dabf23171b37f8b1335dfdb81d408f8b95391aea6d4066aecc9fde01dfe',
    }
    default['dovecot']['checksums']['lmtpd'] = {
      'x86_64' => '833b243e28c7baff141ecf37456e310f5d836e7944a3b9f2fe5074adf0d6a418',
      'aarch64' => '55af47a121ba7e23966b20ddaab2dff7feba4b34677864e045e31a702afa180d',
    }
  end
end
