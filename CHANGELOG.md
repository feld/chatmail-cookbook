# chatmail CHANGELOG

This file is used to list changes made in each version of the chatmail cookbook.

## 0.2.3

### Changes
- Automatically update /etc/aliases.db if it is out of date
- Update chatmaild to 0.3-9bf99cc8a9fa97358ca63fc7e23531b482e0d610

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
