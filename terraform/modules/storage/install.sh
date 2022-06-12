#!/bin/bash
apt-get -y update
apt-get install -y postgresql

systemctl start postgresql.service

sudo -i -u postgres psql -c "ALTER USER postgres PASSWORD 'cloudacademy';"
sudo -i -u postgres psql -c "CREATE DATABASE cloudacademy;"

echo fin v1.00!
