#!/bin/bash

set -e

PORT=7777

target=/opt/dnsmasq-rest-api/

echo "Installing dnsmasq-rest-api to $target."

[ -d $target ] || git clone git://github.com/terrancesnyder/dnsmasq-rest-api.git $target

echo "Configuring dnsmasq."

ln -sf $target/config/dnsmasq/dnsmasq-rest-api.conf /etc/dnsmasq.d/dnsmasq-rest-api.conf
/etc/init.d/dnsmasq restart

echo "Allow dnsmasq-rest-api to send signal to dnsmasq"

cp $target/config/sudo/dnsmasq /etc/sudoers.d/dnsmasq
chmod 0440 /etc/sudoers.d/dnsmasq

echo "Configuring apache2"

a2enmod rewrite
ln -sf $target/config/apache2/dnsmasq-rest-api.conf /etc/apache2/conf-enabled/dnsmasq-rest-api.conf
sudo service apache2 restart
chown -R www-data $target/zones
cp $target/www/config.example.php $target/www/config.php

echo "Dnsmasq-rest-api installed."

echo "Running tests."

echo "* Listing zones"
curl -s http://localhost:$PORT/dnsmasq-rest-api/zones | grep "\\[" | grep "\\]"
echo "* Adding records"
curl -s -X POST http://localhost:$PORT/dnsmasq-rest-api/zones/myTest/127.0.0.2/localhost.test | grep OK
echo "* Reload dnsmasq"
curl -s -X POST http://localhost:$PORT/dnsmasq-rest-api/reload | grep OK
echo "* Testing dns"
nslookup localhost.test 127.0.0.1 | grep 127.0.0.2
echo "* Removing test zone"
curl -s -X DELETE http://localhost:$PORT/dnsmasq-rest-api/zones/myTest | grep OK

echo "Tests ok."
