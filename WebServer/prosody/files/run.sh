#!/bin/bash

export admin_backend="$(host admin_backend | grep "^admin_backend has address " | awk 'NF>1{print $NF}')"
rm -f /etc/prosody/conf.d/site.cfg.lua
envsubst  < /config/conf.d/site.cfg.lua.tmp > /etc/prosody/conf.d/site.cfg.lua
chown -R root:prosody /etc/prosody/conf.d
exec s6-setuidgid prosody prosody --config /etc/prosody/prosody.cfg.lua -F

#exec sleep 1h


