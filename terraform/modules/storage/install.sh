#!/bin/bash
apt-get -y update
apt-get -y install postgresql
apt-get -y install jq tree

systemctl start postgresql.service

sudo -i -u postgres psql -c "ALTER USER postgres PASSWORD 'cloudacademy';"
sudo -i -u postgres psql -c "CREATE DATABASE cloudacademy;"

echo fin v1.00!
