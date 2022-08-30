#!/bin/bash

ROOT=/app
DATA_DIR=$ROOT/data
CERTI_DIR=$ROOT/certificate
SERVER_DIR=$ROOT/server

function output() {
    echo -e "\e[0;33m[config] $1\e[0m"
}

output "server ip"
read -p "enter server ip: " SERVER_IP
output "SERVER_IP: $SERVER_IP"

output "certificate"
read -p "certificate create? [y/n] " INPUT

if [ "x$INPUT" = "xy" ]; then
    output "certificate password"
    read -p "certificate password: " CERTI_PASSWORD

    output "certificate common name"
    read -p "certificate common name: " CERTI_NAME

    if [ "x$CERTI_NAME" = "x" ]; then
        CERTI_NAME="PowerManager"
    fi

    sed -i -e "s,IP.1    = 10.0.0.4,IP.1    = $SERVER_IP,g" $CERTI_DIR/Server.cfg
 
    output "generate root certificate ..."
    openssl genrsa -out $CERTI_DIR/private/ca.key
    echo -e "\n\n\n\n${CERTI_NAME}\n\n\n\n" | openssl req -new -key $CERTI_DIR/private/ca.key -out $CERTI_DIR/certs/ca.csr -config $CERTI_DIR/Server.cfg
    openssl x509 -req -days 3650 -extensions v3_ca -in $CERTI_DIR/certs/ca.csr -signkey $CERTI_DIR/private/ca.key -out $CERTI_DIR/newcerts/ca.crt -extfile $CERTI_DIR/Server.cfg
    openssl pkcs12 -inkey $CERTI_DIR/private/ca.key -in $CERTI_DIR/newcerts/ca.crt -export -out $CERTI_DIR/newcerts/ca.p12 -passout pass:$CERTI_PASSWORD
  
    output "generate server certificate ..."
    openssl genrsa -out $CERTI_DIR/private/S.key
    echo -e "\n\n\n\n$SERVER_IP\n\n\n\n" | openssl req -new -key $CERTI_DIR/private/S.key -out $CERTI_DIR/certs/S.csr -config $CERTI_DIR/Server.cfg
    openssl x509 -req -days 3650 -extensions v3_req -in $CERTI_DIR/certs/S.csr -CA $CERTI_DIR/newcerts/ca.crt -CAcreateserial -CAkey $CERTI_DIR/private/ca.key -out $CERTI_DIR/newcerts/S.crt -extfile $CERTI_DIR/Server.cfg
    openssl pkcs12 -inkey $CERTI_DIR/private/S.key -in $CERTI_DIR/newcerts/S.crt -export -out $CERTI_DIR/newcerts/S.p12 -passout pass:$CERTI_PASSWORD

    output "generate client certificate ..."
    openssl genrsa -out $CERTI_DIR/private/C.key
    echo -e "\n\n\n\n\n${CERTI_NAME}\n\n\n\n" | openssl req -new -key $CERTI_DIR/private/C.key -out $CERTI_DIR/certs/C.csr -config $CERTI_DIR/Client.cfg
    openssl x509 -req -days 365 -extensions v3_user_req -in $CERTI_DIR/certs/C.csr -CA $CERTI_DIR/newcerts/ca.crt -CAcreateserial -CAkey $CERTI_DIR/private/ca.key -out $CERTI_DIR/newcerts/C.crt -extfile $CERTI_DIR/Client.cfg
    openssl pkcs12 -inkey $CERTI_DIR/private/C.key -in $CERTI_DIR/newcerts/C.crt -export -out $CERTI_DIR/newcerts/C.p12 -passout pass:$CERTI_PASSWORD

    output "copy generated certificate files ..."
    cp -ar -v $CERTI_DIR/newcerts $DATA_DIR/
fi

output "register root certificate ..."
rm /usr/local/share/ca-certificates/ca.crt
update-ca-certificates
cp $DATA_DIR/newcerts/ca.crt /usr/local/share/ca-certificates/ca.crt
update-ca-certificates

output "dns server settings ..."
DNS_IP_3ADDR=$(echo $SERVER_IP | awk -F'.' '{OFS="."; print $3,$2,$1}')
DNS_IP_4TH_ADDR=$(echo $SERVER_IP | awk -F'.' '{print $4}')

cat << 'EOF' > /etc/bind/db.$DNS_IP_3ADDR
$TTL    86400
@       IN      SOA     dawonai.com. root (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      dawonai.com
@       IN      A       DJJPROJECT_CONF_SERVER_IP
DJJPROJECT_CONF_4TH_ADDR     IN      PTR     dawonai.com.
DJJPROJECT_CONF_4TH_ADDR     IN      PTR     dwmqtt.dawonai.com
DJJPROJECT_CONF_4TH_ADDR     IN      PTR     dwapi.dawonai.com
EOF

sed -i -e "s,DJJPROJECT_CONF_SERVER_IP,$SERVER_IP,g" /etc/bind/db.$DNS_IP_3ADDR
sed -i -e "s,DJJPROJECT_CONF_4TH_ADDR,$DNS_IP_4TH_ADDR,g" /etc/bind/db.$DNS_IP_3ADDR
sed -i -e "s,DJJPROJECT_CONF_3_ADDR,$DNS_IP_3ADDR,g" /etc/bind/named.conf.local
sed -i -e "s,DJJPROJECT_CONF_SERVER_IP,$SERVER_IP,g" /etc/bind/db.dawonai.com
  
output "checks dns server lookup ..."
/etc/init.d/bind9 stop
/etc/init.d/bind9 start
nslookup dwmqtt.dawonai.com $SERVER_IP
nslookup dwapi.dawonai.com $SERVER_IP
nslookup dawonai.com $SERVER_IP

output "server configuration ..."
if [ ! -f $DATA_DIR/config.yml ]; then
    output "no configuration file, install example file"
    cp -v $SERVER_DIR/config/config.yml.example $DATA_DIR/config.yml
    dos2unix $DATA_DIR/config.yml
    
    sed -i -e "s,ServerCertificate:.*,ServerCertificate: $DATA_DIR/newcerts/S.p12,g" $DATA_DIR/config.yml
    sed -i -e "s,DbPath:.*,DbPath: $DATA_DIR/PowerManager.sqlite,g" $DATA_DIR/config.yml
    
    if [ "x$CERTI_PASSWORD" = "x" ]; then
        output "certificate password"
        read -p "enter server certificate password: " CERTI_PASSWORD
    fi

    sed -i -e "s,ServerCertificatePassword:.*,ServerCertificatePassword: $CERTI_PASSWORD,g" $DATA_DIR/config.yml
    
    output "server configuration finished."
    cat $DATA_DIR/config.yml
    echo ""
else
    output "already config.yml file in $DATA_DIR"
fi




output "finished. please restart container."
