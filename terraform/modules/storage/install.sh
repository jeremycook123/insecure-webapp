#!/bin/bash
apt-get -y update
apt-get -y install jq tree

apt-get -y install postgresql-14
#update config to all connections from app server
echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf
sed -i "s/127\.0\.0\.1\/32/all/g" /etc/postgresql/14/main/pg_hba.conf

systemctl start postgresql.service
systemctl status postgresql.service

sudo -i -u postgres psql -c "ALTER USER postgres PASSWORD 'cloudacademy';"
sudo -i -u postgres psql -c "CREATE DATABASE cloudacademy;"

echo fin v1.00!
