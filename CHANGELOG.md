# chatmail CHANGELOG

This file is used to list changes made in each version of the chatmail cookbook.

## 0.2.5

### Changes

- Strip DKIM-Signature headers before delivering via LMTP (merged upstream)
- FreeBSD: explicitly enable/start syslogd
- Debian: Fix mtail service which was not correctly processing logs
- FreeBSD: Replace the Python filtermail with the new Rust version
- Suppress an LMTP Received header from being appended to messages (upstream)
- FreeBSD: Fix package install when version in repo changes
- Upgrade packages during cookbook run and restart affected services
- FreeBSD: Switch Lego renewal from a root crontab entry to a cron.d file
- Sample zone file has real CAA record
- Cleanly stop services before upgrading packages, then start after
- FreeBSD: Fix chatmail-turn socket file location so it can run as non-root

## 0.2.4

### Changes

- Change Unbound restart signalling to :delayed instead of :immediately
- Move all services to start at the end to avoid order of operations issues during initial deployment
- Unbound: disable negative cache entries to help improve reliability of certificate issuance and DKIM validation
- Debian: Fix cookbook compilation issue
- FreeBSD: Add freebsd_sysrc resource to simplify controlling FreeBSD rc.conf values
- FreeBSD: apply a patch to chatmaild before building instead of shipping a separate tarball
- Update chatmaild to 0.3-c2acbad802a71406fe58892a5a233750382b916d
- Fix message expiration cron only executing in dry-run mode

## 0.2.3

### Changes
- Automatically update /etc/aliases.db if it is out of date
- Update chatmaild to 0.3-9bf99cc8a9fa97358ca63fc7e23531b482e0d610
- FreeBSD: Fix mtail service arguments
- FreeBSD: More robust service management by raising an error if service did not [re]start successfully
- FreeBSD: Fix OpenDKIM verification. This was broken, but technically harmless for Chatmail to Chatmail communication
- FreeBSD: Generate 2048bit DKIM keys. Debian does this by default as they patched their OpenDKIM packages.

## 0.2.2

### BREAKING
- FreeBSD: rc scripts for chatmaild services have been reworked, and will not restart cleanly if you have already deployed. A reboot or manually killing all of the filtermail/doveauth/chatmail-metadata processes and starting the services again will fix it
- The `journald_retention` setting in `attributes.json.example` has been renamed to `log_retention` to be platform agnostic.

### Changes
- Lego: certificate issuance shows stdout so you can see the reason if it fails
- Lego: Fix edge case in where the TLS certificates were not installing to the expected path
- FreeBSD: if you run in a jail, it will reconfigure syslogd to not listen on any network sockets to avoid conflict with the jail host.
- The `certificates_dir` and `mailboxes_dir` settings have been removed from `attributes.json.example`. They can still be configured but most users will never touch them.
- FreeBSD: ZFS settings are available in the `attributes.json.example` file now.
- FreeBSD: fixed Nginx configuration's hardcoded path to syslog socket (/dev/log) to work correctly on FreeBSD (/var/run/log).
- FreeBSD: Prevent every package installation from doing the equivalent of "pkg update" first.
- FreeBSD: Fix dovecot service not actually getting enabled/started after some refactoring
- FreeBSD: Postfix was not able to verify certificates when federating (outbound) emails with `smtp_tls_CApath=/etc/ssl/certs`; switched to `smtp_tls_CApath=/etc/ssl/cert.pem`.
- Dovecot: enable IMAP hibernation on Debian to sync with upstream's configuration. This does not work on FreeBSD right now [b78283c](https://github.com/dovecot/core/commit/b78283cf9748e4c4fed8a5ec09cdba7b9bf18228). Only benefit is lowered memory usage for many idle connections.
- FreeBSD: patched turnserver, part of chatmaild, which had a hardcoded socket path meant for Debian.

## 0.2.1

### Changes
- Fix deploy path of www files due to mistake during refactoring
- Improve FreeBSD deployment by disabling FreeBSD-ports pkg repo and attempting to upgrade packages from the Chatmail repo
- Deploy key for verifying FreeBSD package signatures

## 0.2.0

### Changes
- Reorganized cookbook to better support multiple OSes
- FreeBSD support
- Versioning of the cookbook will be taken seriously now

## 0.1.0

Initial release.
