Supported Distros
=================

This is only known to work on 32-bit Debian 6 (Squeeze). It is also known
to fail on Ubuntu 12.04 because Python 2.5.6 won't build, though I suspect
that's a package thing.

Installing Canary
=================

Most of this is handled by the scripts, so you shouldn't have to do much.

First, though, you'll need to get this repo on the VM. It is assumed that you
do this by creating a keypair on the VM and adding that to your github account,
which will allow the script to clone the private canary repo later.

Currently the only configurable thing is the name of the user that will own the
canary installation and run the processes. Defaults to 'canary', can be changed
at the top of setup.sh.

The first thing to do is run bin/setup.sh from the root of this repo. You'll see
a bunch of packages getting installed. The MySQL package will ask you for
a password for the root MySQL user. Pick a good one. Keep it secret, keep it
safe, and keep it handy; you'll need this later on.

After the packages install, it's time to build and install python. This'll take
about five minutes.

Next, you'll be asked to set the password and some other info for the canary
user. Either pick a good one or disable logins for this user, your choice.

After the new user is created, the python dependencies of canary will be
installed. During this part you'll be asked for the password for the canary
user so they can sudo. This is just during the installation; the canary user
will be removed from the sudoers file at the end of installation.

Once the python dependencies have been installed, it's time to clone canary
and configure it. If you set a password for the private key on this VM, you'll
be asked for it now.

Part of configuring canary involves creating the MySQL database, which requires
that you enter the MySQL root password you created earlier. Now the script will
load the production canary database, which may take some time (don't worry;
we're more than halfway there!).

Now it's your turn to step up to the plate. You'll be asked to edit the
canary_config.py file. All of the paths and database options in here are already
properly configured, you should just change the server name, cookie domain,
email addresses, and the like. (I'm Not entirely sure what the server named by
the MAIL_SERVER variable needs to have; that's a question for DChud.)

With configuration over, canary can finally be installed into its virtualenv.
After installation, the test_lucene_indexing script is run, which seems to be
necessary to load the data. The script will load up through record index 6826
but only load 6566 records total. Some of this is due to missing records, others
might be due to a few records that have bad string data that causes python to
complain about the encoding.

Once the records are loaded, the scgi handler will be started and the script
will finish. If you see a Python stack trace, something went wrong. If not,
you'll see the site on the server's port 80!
