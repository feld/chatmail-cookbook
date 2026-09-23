# Firewall

The following is a list of services and their ports you should open for full functionality

- Postfix: 25/tcp 465/tcp 587/tcp
- Dovecot: 143/tcp 993/tcp
- Iroh Relay: 3340/tcp 7842/udp
- Chatmail-Turn (Linux): 32768-60999/udp (/proc/sys/net/ipv4/ip_local_port_range)
- Chatmail-Turn (FreeBSD): 49152-65535/udp on FreeBSD (net.inet.ip.portrange.hifirst and net.inet.ip.portrange.hilast)
- Nginx: 80/tcp (optional) and 443/tcp
