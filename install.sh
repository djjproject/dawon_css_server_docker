#!/bin/bash

# install dependencies
apt update
DEBIAN_FRONTEND=noninteractive apt install -y sudo curl git wget vim dialog ca-certificates libicu60 locales \
    tzdata openssl unzip dos2unix net-tools dnsutils bind9

# dir create
mkdir -p /app/data/{newcerts,data}
mkdir -p /app/{temp,server,certificate}

# locale
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8

# timezone
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# get powermanager server / certificate
wget https://github.com/SeongSikChae/PowerManagerServerV2/releases/download/449885d5/Linux64-449885d5.zip -O /app/temp/server.zip
wget https://github.com/SeongSikChae/Certificate/releases/download/v1.0.0/Certificate.zip -O /app/temp/certificate.zip

# install certificate
unzip /app/temp/certificate.zip -d /app/certificate

# install server
unzip /app/temp/server.zip -d /app/server

# cleanup
apt clean
rm -rf /app/temp
