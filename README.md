# Chatmail

This is a rough Chef cookbook for deploying Chatmail. This is what I use to deploy my server. Check the `attributes/default.rb` to see which attributes you may need to set on your target node.

Everything is handled: Nginx, Postfix, the patched Dovecot, DKIM, journald log retention changes, the extra Chatmail related services (echobot, etc). It's all here.

Future changes to Chatmail will need to be synced into this cookbook but it is only a minor inconvenience.

Patches welcome, of course.

## ACME Certs / Lego

To make this work, you'll need to put a lego binary in `files/default` which will be deployed to the server or modify the cookbook to fetch it from wherever you prefer. I used the latest from [here](https://github.com/go-acme/lego/releases).

The drawback of the official Chatmail deployment is the expectation that you can do HTTP-01 validation on your server. This cookbook uses DNS-01 validation instead.

Background: my original deployment used a custom ACME plugin in Chef that I wrote for my preferred DNS provider, DNSimple. That's not suitable for others to use, so I rewrote that piece to use Lego. I was originally going to just use the packaged version of lego in Debian but discovered it's slightly too old and does not support DNSimple. So instead I'm just shipping a lego binary now.

## Divergences

The HTML templates have had a few tweaks. The QR code is generated with a different tool and doesn't embed the Deltachat logo. Otherwise it's mostly the same.

It does not check or report the DNS records you're supposed to set. It's possible to get Chef to construct the values and print them out for your reference, but I didn't do that yet.

## Warranty

There is none. :)

Also storing your OAuth token or whatever for your DNS provider in the node attributes is not Best Practices^TM but it's not the end of the world.

## OS Support

It's assuming you're running on Debian and I expect it will work on Ubuntu. It could likely support RHEL as a target easily. I hope to support FreeBSD in the future as that's my preferred server OS.

## Final notes

I didn't setup any Chef tests. It's a little hacky because it was a direct conversion of the cmdeploy logic and templates. If you would prefer to use Ansible this cookbook is probably an easier starting point as the steps and logic are a bit clearer. You'll have to convert the templates back to Jinja from ERB. Otherwise it should be very straightforward.

