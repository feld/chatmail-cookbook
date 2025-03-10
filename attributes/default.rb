# Don't forget to update the attributes.json.example if attributes are changed/added
default['chatmail']['certificates_dir'] = '/etc/lego/certificates'
default['chatmail']['debug'] = false
default['chatmail']['delete_inactive_users_after'] = 90
default['chatmail']['delete_mails_after'] = 20
default['chatmail']['disable_ipv6'] = false
default['chatmail']['dkim_selector'] = 'opendkim'
default['chatmail']['domain'] = 'example.com'
default['chatmail']['filtermail_smtp_port'] = 10080
default['chatmail']['imap_rawlog'] = false
default['chatmail']['journald_retention'] = '3d'
default['chatmail']['mailboxes_dir'] = '/home/vmail/mail'
default['chatmail']['max_mailbox_size'] = '100M'
default['chatmail']['max_message_size'] = 31457280
default['chatmail']['max_user_send_per_minute'] = 60
default['chatmail']['mtail']['address'] = '127.0.0.1'
default['chatmail']['passthrough_recipients'] = 'xstore@testrun.org'
default['chatmail']['passthrough_senders'] =
default['chatmail']['password_min_length'] = 9
default['chatmail']['postfix_reinject_port'] = 10025
default['chatmail']['privacy_mail'] = 'UNDEFINED'
default['chatmail']['privacy_pdo'] = 'UNDEFINED'
default['chatmail']['privacy_postal'] = 'UNDEFINED'
default['chatmail']['privacy_supervisor'] = 'UNDEFINED'
default['chatmail']['username_max_length'] = 9
default['chatmail']['username_min_length'] = 9
default['chatmail']['webdev'] = false

default['chatmaild']['release'] = '0.2'

default['lego']['path'] = '/etc/lego'
default['lego']['email'] = 'you@example.com'
default['lego']['envs'] = { 'DNSIMPLE_OAUTH_TOKEN' => 'abcd1234' }
default['lego']['provider'] = 'dnsimple'
