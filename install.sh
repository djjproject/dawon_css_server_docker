#!/bin/bash

TIMEZONE="Asia/Seoul"
SERVER_URL="https://github.com/SeongSikChae/PowerManagerServerV2/releases/download/449885d5/Linux64-449885d5.zip"
CERTI_URL="https://github.com/SeongSikChae/Certificate/releases/download/v1.0.0/Certificate.zip"

ROOT=/app
CERTI_DIR=$ROOT/certificate
SERVER_DIR=$ROOT/server
TEMP_DIR=$ROOT/temp
DATA_DIR=$ROOT/data

# install dependencies
apt update
DEBIAN_FRONTEND=noninteractive apt install -y sudo curl git wget vim dialog ca-certificates libicu60 locales \
    tzdata openssl unzip dos2unix net-tools dnsutils bind9

# dir create
mkdir -p $CERTI_DIR $SERVER_DIR $TEMP_DIR $DATA_DIR

# locale
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8

# timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# get powermanager server / certificate
wget ${SERVER_URL} -O $TEMP_DIR/server.zip
wget ${CERTI_URL} -O $TEMP_DIR/certificate.zip

# install server / certificate
unzip $TEMP_DIR/server.zip -d $SERVER_DIR
unzip $TEMP_DIR/certificate.zip -d $CERTI_DIR

# certificate
cd $CERTI_DIR
dos2unix Server.cfg
dos2unix Client.cfg

sed -i -e "s,HOME\t\t\t=.*,HOME\t\t\t= $CERTI,g" $CERTI_DIR/Server.cfg
sed -i -e "s,HOME\t\t\t=.*,HOME\t\t\t= $CERTI,g" $CERTI_DIR/Client.cfg

# dns server configuration
cat << 'EOF' > /etc/bind/named.conf.local
zone "dawonai.com" IN {
        type master;
        file "/etc/bind/db.dawonai.com";
        allow-update { none; };
        allow-transfer { none; };
};

zone "DJJPROJECT_CONF_3_ADDR.in-addr.arpa" IN {
        type master;
        file "/etc/bind/db.DJJPROJECT_CONF_3_ADDR";
        allow-update { none; };
        allow-transfer { none; };
};
EOF

cat << 'EOF' > /etc/bind/db.dawonai.com
$TTL    86400
@       IN      SOA     dawonai.com. root (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      dawonai.com.
@       IN      A       DJJPROJECT_CONF_SERVER_IP
dwmqtt  IN      A       DJJPROJECT_CONF_SERVER_IP
dwapi   IN      A       DJJPROJECT_CONF_SERVER_IP
EOF

# cleanup
apt clean
rm -rf /app/temp
