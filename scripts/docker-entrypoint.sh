#!/bin/sh

PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

mkdir -p /paperclip/instances/default

if [ ! -f /paperclip/instances/default/config.json ]; then
    echo "Creating config.json..."
    cat > /paperclip/instances/default/config.json << 'EOF'
{
  "server": {
    "host": "0.0.0.0",
    "port": 3100,
    "deploymentMode": "authenticated",
    "deploymentExposure": "public",
    "publicBaseUrl": "https://paperclip-production-78e0.up.railway.app"
  }
}
EOF
    chown node:node /paperclip/instances/default/config.json
fi

echo "--- Bootstrap starting ---"
gosu node node --import ./server/node_modules/tsx/dist/loader.mjs cli/src/index.js auth bootstrap-ceo 2>&1 || true
echo "--- Bootstrap complete ---"

exec gosu node "$@"
