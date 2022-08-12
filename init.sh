#!/bin/bash

# start PowerManager Server
mkdir -p /app/data/log
nohup /app/server/PowerManagerServer --config /app/data/config.yml --log /app/data/log < /dev/null > /dev/null 2>&1 &

# start dns server
/etc/init.d/bind9 start

# dummy
/bin/bash
