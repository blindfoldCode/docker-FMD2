#!/bin/bash
if [ ! -f '/app/FMD2/userdata/settings.json' ]; then cp /settings.json /app/FMD2/userdata/settings.json; fi
mkdir -p /app/FMD2/src
echo 'alias python=python3' >> ~/.bashrc
git clone --single-branch --depth=1 https://github.com/dazedcat19/FMD2.git /app/FMD2/src
# restore previous settings
[ -f "/app/FMD2/lua/websitebypass/websitebypass_config.json" ] && cp /app/FMD2/lua/websitebypass/websitebypass_config.json /app/FMD2/src/lua/websitebypass/websitebypass_config.json
cp /app/FMD2/src/lua /app/FMD2 -R
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix -R
chown abc:abc /app -R
chown abc:abc /config -R
chown abc:abc /app/FMD2/lua -R
chown abc:abc /downloads -R
chown abc:abc /wine -R
chown abc:abc /tmp/wine-FB4NvD -R
chmod +x /usr/local/bin/sync_dir
