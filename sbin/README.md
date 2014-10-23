SBIN directory
===============

This directory is used on non-salted heterogenous environments.

You'll find here some of the development tools that can be used to facilitate deployments and installation in places where you do not have salt-stack and corpus.

This is not set in `/bin` but `/sbin` as `/bin` is used by the salted deployment to generate contextual scripts.

Theses scripts, expecially user_rights and deplo.sh can help you manage a Drupal deployment with `www/sites/default` linked to `/sites/default`. 

Note that salted envs do not use the `/sites` directory but a specific `/data` direcory for such behaviors. It also does not use settings templates (`settings.php`, `common.settings.php`, `local.settings.php`) files from `/sites` but from `.salt/files/` templates with default values taken from `.salt/PILLAR.sample`.


## INSTALL

To start a deployment in a non salted env edit the deploy.dev.conf file (adjust the user, for example) and run:

    sudo ./sbin/deploy.sh DEV

This will connect the symlinks for `www/sites/default` and install `composer` and `drush` in this sbin and init the user and group rights on the projetc.

It could also install nginx, php, etc. But do not be afraid you can always choose to avoid some steps of this deploy script.
