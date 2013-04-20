#!/bin/bash
# install canary itself
#
# note that we assume that our working directory is the canary install root

set -e

source ENV/bin/activate

# install the project
pushd canary
python setup.py install
popd

# create dirs referenced in canary_config.py
mkdir -p log
mkdir -p search-index
mkdir -p tmp
mkdir -p upload

# install apache2 scgi module
pushd downloads/scgi-1.13/apache2
make
sudo make install
popd

# configure apache mods, sites
sudo cp canary/conf/etc/apache2/mods/* /etc/apache2/mods-available/
sudo ln -s /etc/apache2/mods-available/scgi.conf /etc/apache2/mods-enabled/scgi.conf
sudo ln -s /etc/apache2/mods-available/scgi.load /etc/apache2/mods-enabled/scgi.load

sudo cp canary/conf/etc/apache2/sites/* /etc/apache2/sites-available/
sudo ln -s /etc/apache2/sites-available/canary /etc/apache2/sites-enabled/canary
sudo rm /etc/apache2/sites-available/*default

sudo service apache2 restart

# add temp image removal script
sudo cp canary/conf/etc/cron.daily/canary /etc/cron.daily/

# create and load database
echo "Please enter the MySQL root password"
echo "create database canary_prod character set utf8; grant all on canary_prod.* to 'canary'@'localhost';" | mysql -u root -p
mysql canary_prod < canary/doc/database-schema.sql

pushd downloads
wget https://s3.amazonaws.com/canarydatabase.org/20130227-canary_prod.sql.gz
gunzip 20130227-canary_prod.sql.gz
printf "Loading production database..."
mysql canary_prod < 20130227-canary_prod.sql
printf "DONE\n"
popd
