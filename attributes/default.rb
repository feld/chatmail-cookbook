# Don't forget to update the attributes.json.example if attributes are changed/added
default['chatmail']['debug'] = false
default['chatmail']['delete_inactive_users_after'] = 90
default['chatmail']['delete_large_after'] = 7
default['chatmail']['delete_mails_after'] = 20
default['chatmail']['disable_ipv6'] = false
default['chatmail']['disable_registration'] = false
default['chatmail']['dkim_selector'] = 'opendkim'
default['chatmail']['domain'] = 'example.com'
default['chatmail']['imap_rawlog'] = false
default['chatmail']['imap_compress'] = false
default['chatmail']['iroh_relay'] = false
default['chatmail']['log_retention'] = '3d'
default['chatmail']['mailboxes_dir'] = lazy { "#{node['chatmail']['vmail_home']}/mail" }
default['chatmail']['max_mailbox_size'] = '100M'
default['chatmail']['max_message_size'] = 31457280
default['chatmail']['max_user_send_per_minute'] = 60
default['chatmail']['mtail']['address'] = '127.0.0.1'
default['chatmail']['passthrough_recipients'] = ''
default['chatmail']['passthrough_senders'] = nil
default['chatmail']['password_min_length'] = 9
default['chatmail']['privacy_mail'] = 'UNDEFINED'
default['chatmail']['privacy_pdo'] = 'UNDEFINED'
default['chatmail']['privacy_postal'] = 'UNDEFINED'
default['chatmail']['privacy_supervisor'] = 'UNDEFINED'
default['chatmail']['username_max_length'] = 9
default['chatmail']['username_min_length'] = 9
default['chatmail']['webdev'] = false

default['lego']['email'] = 'you@example.com'
default['lego']['envs'] = { 'DNSIMPLE_OAUTH_TOKEN' => 'abcd1234' }
default['lego']['provider'] = 'dnsimple'
default['lego']['release'] = 'v4.28.1'

default['filtermail']['release'] = 'v0.2.0'
default['filtermail']['checksums'] = {
  'x86_64' => '0918f596e1f218fb96fc3d9bff7e205c79ef6bf074cf70dbfc0e2522d4072574',
  'x86_64-musl' => '1e5bbb646582cb16740c6dfbbca39edba492b78cc96ec9fa2528c612bb504edd',
  'aarch64' => 'e96914f96a5288981f01147d1d1591d68dd2e78d8d9250242c5249718e07a341',
  'aarch64-musl' => '3564fba8605f8f9adfeefff3f4580533205da043f47c5968d0d10db17e50f44e'
}

default['freebsd']['zfs']['enable'] = false
# The ZFS dataset name, but by default it will use the mailboxes_dir
# for the mountpoint
default['freebsd']['zfs']['vmail_dataset'] = 'zroot/home/vmail'
default['freebsd']['zfs']['vmail_quota'] = 'none'
