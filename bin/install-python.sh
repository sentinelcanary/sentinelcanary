#!/bin/bash
# This script doesn't really care where it's called from; it does its stuff in
# a temporary directory

set -e

# AUTO: mysql asks for new mysql root password
sudo apt-get install -y make gcc build-essential apache2 apache2-dev memcached mysql-server zlibc zlib1g-dev git ca-certificates unzip bzip2

sudo cp /usr/share/mysql/config.small.ini /etc/mysql/conf.d/

py_dir=`mktemp -d /tmp/py-install-XXXXX`
pushd $py_dir

# build & install python 2.5.6
wget http://python.org/ftp/python/2.5.6/Python-2.5.6.tgz
tar xzf Python-2.5.6.tgz
pushd Python-2.5.6

./configure --enable-unicode=ucs2 --prefix=/usr/local
make
sudo make install

popd

# install setup tools & virtualenv
wget http://python-distribute.org/distribute_setup.py
sudo /usr/local/bin/python distribute_setup.py
sudo easy_install virtualenv

# install ssl module
wget https://pypi.python.org/packages/source/s/ssl/ssl-1.15.tar.gz
tar xzf ssl-1.15.tar.gz
pushd ssl-1.15
sudo python setup.py install
popd
sudo rm -rf ssl-1.15*

popd
sudo rm -rf $py_dir
