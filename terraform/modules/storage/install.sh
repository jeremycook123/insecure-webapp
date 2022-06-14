#!/bin/bash
apt-get -y update
apt-get -y install jq tree

apt-get -y install postgresql-14
#update config to all connections from app server
echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf
sed -i "s/127\.0\.0\.1\/32/all/g" /etc/postgresql/14/main/pg_hba.conf

systemctl restart postgresql.service
systemctl status postgresql.service

sudo -i -u postgres psql -c "ALTER USER postgres PASSWORD 'cloudacademy';"
sudo -i -u postgres psql -c "CREATE DATABASE cloudacademy;"

sudo -i -u postgres psql -c "CREATE TABLE IF NOT EXISTS users(user_id VARCHAR (36) PRIMARY KEY, username VARCHAR (50) UNIQUE NOT NULL, password VARCHAR (50) NOT NULL, created_on TIMESTAMP NOT NULL, last_login TIMESTAMP);"
sudo -i -u postgres psql -c "CREATE TABLE IF NOT EXISTS comments(id VARCHAR (36) PRIMARY KEY, username VARCHAR (36), body VARCHAR (500), created_on TIMESTAMP NOT NULL);"

#insert USERS seed data 
sudo -i -u postgres psql -c "INSERT INTO users (user_id, username, password, created_on) VALUES ('$(uuidgen)', 'admin', '$(echo secretpassword | md5sum | cut -b-32)', current_timestamp);"
sudo -i -u postgres psql -c "INSERT INTO users (user_id, username, password, created_on) VALUES ('$(uuidgen)', 'alice', '$(echo password | md5sum | cut -b-32)', current_timestamp);"
sudo -i -u postgres psql -c "INSERT INTO users (user_id, username, password, created_on) VALUES ('$(uuidgen)', 'bob', '$(echo password | md5sum | cut -b-32)', current_timestamp);"
sudo -i -u postgres psql -c "INSERT INTO users (user_id, username, password, created_on) VALUES ('$(uuidgen)', 'joe', '$(echo password | md5sum | cut -b-32)', current_timestamp);"

#insert COMMENTS seed data 
sudo -i -u postgres psql -c "INSERT INTO comments (id, username, body, created_on) VALUES ('$(uuidgen)', 'bob', 'good times ahead', current_timestamp);"
sudo -i -u postgres psql -c "INSERT INTO comments (id, username, body, created_on) VALUES ('$(uuidgen)', 'alice', 'security review required', current_timestamp);"
sudo -i -u postgres psql -c "INSERT INTO comments (id, username, body, created_on) VALUES ('$(uuidgen)', 'joe', 'lets roll', current_timestamp);"

echo fin v1.00!
