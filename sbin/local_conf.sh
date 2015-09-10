#!/usr/bin/env bash
# MANAGED VIA SALT !
# 
# 
# 
# . "$(dirname ${0})/get-base.sh"

# Copy this file in the same directory
# and rename it to profile_conf.sh
# Enter property to used during drupal install

ROOTPATH="/srv/projects/c3d/project"
BINPATH="/srv/projects/c3d/project/sbin"
WWW_DIR="/srv/projects/c3d/project/www"
DATA_DIR="/srv/projects/c3d/data/var/sites"
PROJECT_CONFIG_PATH="${ROOTPATH}/sbin/templates"

# System User
USER="c3d-user"
GROUP="editor"

#user right bash script path
#It should be absolute
# 1st arg is the file editor user,
# 2nd argument is the web server/php-fpm group (which may need some write rights on specific places)
# 3rd argument CAN be DEV or empty
USER_RIGHTS="/srv/projects/c3d/global-reset-perms.sh"

# Whether we are in dev mode or not...
# 
DEV_MODE="${DEV_MODE:-}"

#
# drush make related
#
# Profile to use
PROJECT_NAME="c3d"
DRUPAL_URI="http://staging-c3d.makina-corpus.net"
DRUSH_EXTRA_ARGS="--uri="${DRUPAL_URI}""
FORCE_MAKE_MARKER="/srv/projects/c3d/data/force_make"
# 
FORCE_MAKE=""
# 
MAKE_MODULES_CHECK="/srv/projects/c3d/project/www/sites/all/modules/token /srv/projects/c3d/project/www/sites/all/modules/pathauto"

#
# drush install related
#
FORCE_INSTALL_MARKER="/srv/projects/c3d/data/force_make"
# 
FORCE_INSTALL=""
# 
INSTALL_MARKER="/srv/projects/c3d/data/installed"

unset -v TARGETS
declare -A TARGETS
TARGETS["root@localhost"]="/srv/projects/c3d/data/testsync"
# vim:set et sts=4 ts=4 tw=80:
