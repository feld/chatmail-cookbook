#!/bin/sh

/usr/sbin/service nginx reload
/usr/sbin/service postfix reload
/usr/sbin/service dovecot reload