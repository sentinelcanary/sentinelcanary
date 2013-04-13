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

# install python and other system dependencies
./bin/install-python.sh

# create user & add to sudoers
sudo adduser $USER
echo "canary ALL=(ALL) ALL" | sudo tee -a /etc/sudoers >/dev/null

# create canary installation directory & go there
sudo mkdir -p $CANARY_HOME
sudo chown $USER:$USER $CANARY_HOME

pushd $CANARY_HOME

# create project's virtual env
$AS_USER 'virtualenv --no-site-packages --python=/usr/local/bin/python ENV'
source ENV/bin/activate

# install project's python dependencies
$AS_USER "$WORKING_DIR/bin/install-deps.sh"

# clone the project
sudo chmod 777 $CANARY_HOME
git clone git@github.com:lynaghk/canary
pushd canary
git checkout -b redeploy origin/redeploy
popd
sudo chown -R $USER:$USER canary
sudo chmod 755 $CANARY_HOME

# install & configure
$AS_USER "$WORKING_DIR/bin/install-canary.sh"

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

# that should be it
echo "If the SCGI handler would start, then you'd be able to see the site now."
echo "As it stands you'll just get an error from apache after a while."

popd >/dev/null
