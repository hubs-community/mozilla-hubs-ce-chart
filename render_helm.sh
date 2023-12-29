#!/bin/bash

bins=("bash" "openssl" "npm")
for cmd in "${bins[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo "missing required binary: $cmd"
        return 1
    fi
done

if ! npm list -g pem-jwk | grep -q pem-jwk; then
    echo "missing required npm pkg: pem-jwk, try (sudo) npm install pem-jwk -g to install it"
    return 1
fi

read -rsp $'Press any key to continue... (This will wipe your config.yaml)\n' -n1 key

ENV_OUTPUT="configs:\n  data:\n"
### required
HUB_DOMAIN=$1
ADM_EMAIL=$2
DB_USER="postgres"
DB_PASS="123456"
DB_NAME="retdb"
DB_HOST="pgbouncer"
DB_HOST_T="pgbouncer-t"
EXT_DB_HOST="pgsql"
PGRST_DB_URI="postgres://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME"
PSQL="postgres://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME"
# Update with your STMP server settings
SMTP_SERVER="{YOUR_SMTP_SERVER}"
SMTP_PORT="587"
SMTP_USER="{YOUR_SMTP_USER}"
SMTP_PASS="{YOUR_SMTP_PASS}"

NODE_COOKIE="node-{YOUR_NODE_COOKIE_ID}"
GUARDIAN_KEY="{YOUR_GUARDIAN_KEY}"
PHX_KEY="{YOUR_PHX_KEY}"

SKETCHFAB_API_KEY="?"
TENOR_API_KEY="?"

### generate keys and new jwt secret
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
PERMS_KEY=$(echo -n "$(awk '{printf "%s\\\\n", $0}' private_key.pem)")
openssl ec -pubout -in private_key.pem -out public_key.pem

JWT_SECRET=$(pem-jwk public_key.pem)
PGRST_JWT_SECRET=$(pem-jwk public_key.pem)

### initial cert
openssl req -x509 -newkey rsa:2048 -sha256 -days 36500 -nodes -keyout key.pem -out cert.pem -subj '/CN='$1
initCert=$(base64 -i cert.pem | tr -d '\n')
initKey=$(base64 -i key.pem | tr -d '\n')

ENV_OUTPUT+="    DB_USER: \"$DB_USER\"\n"
ENV_OUTPUT+="    DB_PASS: \"$DB_PASS\"\n"
ENV_OUTPUT+="    DB_NAME: \"$DB_NAME\"\n"
ENV_OUTPUT+="    DB_HOST: \"$DB_HOST\"\n"
ENV_OUTPUT+="    DB_HOST_T: \"$DB_HOST_T\"\n"
ENV_OUTPUT+="    EXT_DB_HOST: \"$EXT_DB_HOST\"\n"
ENV_OUTPUT+="    PGRST_DB_URI: \"$PGRST_DB_URI\"\n"
ENV_OUTPUT+="    PSQL: \"$PSQL\"\n"
ENV_OUTPUT+="    SMTP_SERVER: \"$SMTP_SERVER\"\n"
ENV_OUTPUT+="    SMTP_PORT: \"$SMTP_PORT\"\n"
ENV_OUTPUT+="    SMTP_USER: \"$SMTP_USER\"\n"
ENV_OUTPUT+="    SMTP_PASS: \"$SMTP_PASS\"\n"
ENV_OUTPUT+="    NODE_COOKIE: \"$NODE_COOKIE\"\n"
ENV_OUTPUT+="    GUARDIAN_KEY: \"$GUARDIAN_KEY\"\n"
ENV_OUTPUT+="    PHX_KEY: \"$PHX_KEY\"\n"
ENV_OUTPUT+="    SKETCHFAB_API_KEY: \"$SKETCHFAB_API_KEY\"\n"
ENV_OUTPUT+="    TENOR_API_KEY: \"$TENOR_API_KEY\"\n"
ENV_OUTPUT+="    PGRST_JWT_SECRET: '$(pem-jwk public_key.pem)'\n"
echo -e -n "$ENV_OUTPUT" > config.yaml
printf "%s\n\n" "    PERMS_KEY: '$(echo -n $PERMS_KEY)'" >> config.yaml

ENV_OUTPUT="\n---\n\n"
ENV_OUTPUT="defaultCert:\n"
ENV_OUTPUT+="    tls.crt: '$initCert'\n"
ENV_OUTPUT+="   tls.key: '$initKey'\n---\n"
echo -e -n "$ENV_OUTPUT" >> config.yaml

echo -e "\n\nAdd these vars to your values.yaml:\n\n"
cat config.yaml
echo -e "\n\n"
echo "Check ./config.yaml for the generated configs"
