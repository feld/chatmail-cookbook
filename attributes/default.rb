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

default['freebsd']['zfs']['enable'] = false
# The ZFS dataset name, but by default it will use the mailboxes_dir
# for the mountpoint
default['freebsd']['zfs']['vmail_dataset'] = 'zroot/home/vmail'
default['freebsd']['zfs']['vmail_quota'] = 'none'
