# Chatmail

This is a rough Chef cookbook for deploying [Chatmail](https://github.com/chatmail/server). This is what I use to deploy my server. Check the `attributes/default.rb` to see which attributes you may need to set on your target node.

Everything is handled: Nginx, Postfix, the patched Dovecot, DKIM, journald log retention changes, the extra Chatmail related services (echobot, etc). It's all here.

Future changes to Chatmail will need to be synced into this cookbook but it is only a minor inconvenience.

Patches welcome, of course.

## ACME Certs / Lego

To make this work, you'll need to put a lego binary in `files/default` which will be deployed to the server or modify the cookbook to fetch it from wherever you prefer. I used the latest from [here](https://github.com/go-acme/lego/releases).

The drawback of the official Chatmail deployment is the expectation that you can do HTTP-01 validation on your server. This cookbook uses DNS-01 validation instead.

Background: my original deployment used a custom ACME plugin in Chef that I wrote for my preferred DNS provider, DNSimple. That's not suitable for others to use, so I rewrote that piece to use Lego. I was originally going to just use the packaged version of lego in Debian but discovered it's slightly too old and does not support DNSimple. So instead I'm just shipping a lego binary now.

## Using without a Chef Server

Can you use this without a Chef server? Yes! Here's how:

Install the Chef client. I prefer [CINC](https://cinc.sh), the community Chef fork:

```shell
# or go to their website and fetch the package / add their
# package repo if you don't want to curl | bash
curl https://omnitruck.cinc.sh/install.sh  | sudo bash
```

Make a directory structure compatible with a local chef deployment:

```
mkdir -p chef/cookbooks
cd chef
git clone https://github.com/feld/chatmail-cookbook cookbooks/chatmail
cp cookbooks/chatmail/attributes.json.example ./attributes.json
```

Don't forget you need to get a `lego` binary and put it in `cookbooks/chatmail/files/debian/`. You could install from your package manager and symlink it, but the latest release will have better support for DNS-01 validation with more providers. Check the [Lego DNS Providers docs](https://go-acme.github.io/lego/dns/) for details on the ENVs you need to set. 

Edit the `attributes.json` file to suit your environment, including defining the ENVs you need for Lego.

Now you can run the following from inside this `chef/` directory:

```
sudo chef-client -z -o chatmail -j attributes.json
```

This should successfully deploy and configure Chatmail. The full list of DNS records you should deploy for proper federation will be found in `/tmp/chatmail.zone`.


## Divergences

The HTML templates have had a few tweaks. The QR code is generated with a different tool and doesn't embed the Deltachat logo. Otherwise it's mostly the same.

It does not validate DNS records, but it does print out a sample zone file which should be accurate for your deployment. This file can also be found at **/tmp/chatmail.zone** on the server.

## Warranty

There is none. :)

Also storing your OAuth token or whatever for your DNS provider in the node attributes is not Best Practices^TM but it's not the end of the world.

## OS Support

It's assuming you're running on Debian and I expect it will work on Ubuntu. It could likely support RHEL as a target easily. I hope to support FreeBSD in the future as that's my preferred server OS.

## Final notes

I didn't setup any Chef tests. It's a little hacky because it was a direct conversion of the cmdeploy logic and templates. If you would prefer to use Ansible this cookbook is probably an easier starting point as the steps and logic are a bit clearer. You'll have to convert the templates back to Jinja from ERB. Otherwise it should be very straightforward.


## Contact

You can join this [group chat](https://i.delta.chat/#6FE1642916908F1AC9CC7557CC99CF5DDB92043C&a=groupsbot%40testrun.org&g=chatmail%20cookbook%20support&x=Z1oIMyytnazhEY9iZaj2YV_0&i=hnaCYJj6VGMDRu7CHi29Nmaz&s=xDCT_RglgrKaGUJM6-adzZeG) to discuss the cookbook.
