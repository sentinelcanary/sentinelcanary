#!/bin/bash

##
## Configuration
##

USER=canary

##
## Globals
##

# yeah, hardcoded across a bunch of different files
CANARY_HOME=/$USER
AS_USER="sudo su $USER -c"
WORKING_DIR=`pwd`

##
## The Script
##

set -e

# install sudo if not present
if [[ ( ! -e /usr/bin/sudo ) && ( `whoami` == "root" ) ]]; then
  apt-get install sudo
fi

# install python and other system dependencies
./bin/install-python.sh

# create user & add to sudoers
sudo adduser $USER
echo "$USER ALL=(ALL) ALL" | sudo tee -a /etc/sudoers >/dev/null

# create canary installation directory & go there
sudo mkdir -p $CANARY_HOME
sudo chown $USER:$USER $CANARY_HOME

pushd $CANARY_HOME

# create project's virtual env
$AS_USER 'virtualenv --no-site-packages --python=/usr/local/bin/python ENV'
source ENV/bin/activate

# install project's python dependencies
cp $WORKING_DIR/bin/install-deps.sh .
chmod 777 install-deps.sh
$AS_USER "./install-deps.sh"
rm install-deps.sh

# clone the project
sudo chmod 777 $CANARY_HOME
git clone https://github.com/sentinelcanary/sentinelcanary canary
sudo chown -R $USER:$USER canary
sudo chmod 775 $CANARY_HOME

# configure
cp $WORKING_DIR/bin/configure-canary.sh .
chmod 777 configure-canary.sh
$AS_USER "./configure-canary.sh"
rm configure-canary.sh

# remove user from sudoers
sudo cat /etc/sudoers | head -n -1 | sudo tee /etc/sudoers >/dev/null

# copy skeleton canary_config.py, instruct user to customize
$AS_USER "cp canary/conf/canary_config.py.sample canary/conf/canary_config.py"
if [ -z $EDITOR ]; then
  EDITOR=nano
fi
echo "Now it's time to configure canary itself. When you press return, I'll launch"
echo "launch $EDITOR on the production canary config file. If you want to use a"
printf "a different editor, enter its name now [$EDITOR]: "
read MAYBE_DIFFERENT_EDITOR
if [ $MAYBE_DIFFERENT_EDITOR ]; then
  EDITOR=$MAYBE_DIFFERENT_EDITOR
fi
$AS_USER "$EDITOR canary/conf/canary_config.py"

# install & start canary
pushd canary
$AS_USER "source ../ENV/bin/activate;
  python setup.py install;
  ./bin/scripts/test_lucene_indexing.py;
  ./bin/startup.sh;"
popd

# that should be it
echo "All done! You should be able to see the site now."

popd >/dev/null
