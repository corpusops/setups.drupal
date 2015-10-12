#!/usr/bin/env bash
USER="$(whoami)"
# . "$(dirname ${0})/get-base.sh"

# Copy this file in the same directory
# and rename it to profile_conf.sh
# Enter property to used during drupal install

ROOTPATH="/srv/projects/c3d/project"
BINPATH="${ROOTPATH}/sbin"
WWW_DIR="${ROOTPATH}/www"
DATA_DIR="${ROOTPATH}/data/sites"
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
PROJECT_NAME="${PROJECT_NAME}"
DRUPAL_URI="http://${PROJECT_NAME}.local"
DRUSH_EXTRA_ARGS="--uri="${DRUPAL_URI}""
FORCE_MAKE_MARKER="${DATA_DIR}/force_make"
# 
FORCE_MAKE=""
# 
MAKE_MODULES_CHECK="ctools webform token pathauto"

#
# drush install related
#
FORCE_INSTALL_MARKER="${DATA_DIR}/force_install"
# 
FORCE_INSTALL=""
# 
INSTALL_MARKER="${DATA_DIR}/installed"

unset -v TARGETS
declare -A TARGETS
TARGETS["root@localhost"]="${DATA_DIR}/testsync"
# vim:set et sts=4 ts=4 tw=80: 
FORCE_MAKE=""
FORCE_INSTALL=""
# vim:set et sts=4 ts=4 tw=80:
