#!/bin/bash

# install python dependencies of canary.
#
# note that we assume that our working directory is the canary install root
# ('/canary' in the transcript).

##
## Functions
##

function install_from {
# [url] [url artifact]
# run 'setup.py install' from gzipped tarball at url. leaves untarred directory
# in current directory. artifact is for when url doesn't end in
# '$project-x.y.z.tar.gz' (thanks a lot, source forge).

  if [ -z $1]; then
    echo "Too few arguments (need a URL at least)" 1>&2
    return 1;
  fi
  url=$1

  if [ $2 ]; then
    artifact=$2
  else
    artifact=`basename $url`
  fi

  if [[ $3 == "ignore-cert" ]]; then
    wget_flags="--no-check-certificate -O"
  else
    wget_flags="-O"
  fi

  wget $wget_flags $artifact $url
  tar xzf $artifact
  untarred=`echo $artifact | sed -e 's/\.tar\.gz//'`
  pushd $untarred
  python setup.py install

  popd
  rm $artifact
}

function install_from_bad_cert {
  if [ $2 ]; then
    install_from $1 $2 ignore-cert
  else
    install_from $1 ignore-cert
  fi
}

function patch_from {
# [url]
# url is the url of the bare patch file (not gzipped or anything)
  url=$1
  patch=`basename $url`
  wget $url
  patch < $patch
  rm $patch
}

##
## The Script
##

set -e

source ENV/bin/activate

mkdir -p downloads
pushd downloads

# install ssl module
wget https://pypi.python.org/packages/source/s/ssl/ssl-1.15.tar.gz
tar xzf ssl-1.15.tar.gz
pushd ssl-1.15
python setup.py install
popd
rm -rf ssl-1.15*

install_from http://quixote.python.ca/releases/Quixote-1.3.tar.gz
install_from https://pypi.python.org/packages/source/p/python-cjson/python-cjson-1.0.5.tar.gz
install_from https://s3.amazonaws.com/org.aperiodic/canary-deps/Dulcinea-0.1.tar.gz
install_from https://downloads.egenix.com/python/egenix-mx-base-2.0.6.tar.gz
install_from http://sourceforge.net/projects/pyparsing/files/pyparsing/pyparsing-1.3/pyparsing-1.3.tar.gz/download pyparsing-1.3.tar.gz
install_from http://effbot.org/media/downloads/elementtree-1.2.6-20050316.tar.gz
install_from http://effbot.org/media/downloads/Imaging-1.1.5.tar.gz
install_from http://python.ca/scgi/releases/scgi-1.13.tar.gz
install_from http://archive.ipython.org/release/0.10.2/ipython-0.10.2.tar.gz

# patch & install feedparser-4.1
wget https://feedparser.googlecode.com/files/feedparser-4.1.zip
mkdir -p feedparser-4.1
unzip -d feedparser-4.1 feedparser-4.1.zip
rm feedparser-4.1.zip
pushd feedparser-4.1
patch_from http://patch-tracker.debian.org/patch/series/dl/feedparser/4.1-14/feedparser_utf8_decoding.patch
patch_from http://patch-tracker.debian.org/patch/series/dl/feedparser/4.1-14/title_override.patch
patch_from http://patch-tracker.debian.org/patch/series/dl/feedparser/4.1-14/democracynow_feedparser_fix.patch
patch_from http://patch-tracker.debian.org/patch/series/dl/feedparser/4.1-14/auth_handlers_not_working.patch
patch_from http://patch-tracker.debian.org/patch/series/dl/feedparser/4.1-14/add-etag-only-if-etag-header-present.patch
python setup.py install
popd

pip install mysql-python
pip install motionless
pip install unidecode

# install bibutils
wget http://www.scripps.edu/~cdputnam/software/bibutils/bibutils_4.12_i386.tgz
tar xzf bibutils_4.12_i386.tgz
rm bibutils_4.12_i386.tgz
pushd bibutils_4.12
sudo cp * /usr/local/bin/
popd

# install PyLucene
wget https://s3.amazonaws.com/org.aperiodic/canary-deps/PyLucene-0.9.8.tar.gz
tar xzf PyLucene-0.9.8.tar.gz
rm PyLucene-0.9.8.tar.gz
pushd PyLucene-0.9.8
sudo mkdir -p /usr/local/gcc-3.4.3/lib/security
sudo cp *.security /usr/local/gcc-3.4.3/lib/security
sudo cp libgcj.so.5 /usr/local/lib
make install
echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/canary >/dev/null
sudo /sbin/ldconfig
popd

popd
