SBIN directory
===============

This directory is used on non-salted heterogenous environments.

You'll find here some of the development tools that can be used to facilitate deployments and installation in places where you do not have salt-stack and corpus.

This is not set in `/bin` but `/sbin` as `/bin` is used by the salted deployment to generate contextual scripts.

Theses scripts, expecially user_rights and deplo.sh can help you manage a Drupal deployment with `www/sites/default` linked to `/sites/default`. 

Note that salted envs do not use the `/sites` directory but a specific `/data` direcory for such behaviors. It also does not use settings templates (`settings.php`, `common.settings.php`, `local.settings.php`) files from `/sites` but from `.salt/files/` templates with default values taken from `.salt/PILLAR.sample`.
