#!/bin/sh

/usr/bin/systemctl reload nginx
/usr/bin/systemctl reload postfix
/usr/bin/systemctl reload dovecot
