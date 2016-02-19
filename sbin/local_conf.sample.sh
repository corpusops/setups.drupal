#!/usr/bin/env bash
USER="$(whoami)"
# . "$(dirname ${0})/get-base.sh"

# Copy this file in the same directory
# and rename it to local_conf.sh
#
# NOTE: the REAL WAY of generating local_conf.sh
# is running the step 100.sls via salt:
# salt-call -linfo --local mc_project.deploy ${MON_PROJET_A_MOI} only=install only_steps=100_app.sls
#
# But this file is a sample

ROOTPATH="/srv/projects/foo/project"
BINPATH="${ROOTPATH}/sbin"
WWW_DIR="${ROOTPATH}/www"
DATA_DIR="${ROOTPATH}/data/sites"
PROJECT_CONFIG_PATH="${ROOTPATH}/sbin/templates"

# System User
USER="foo-user"
GROUP="foo-grp"

#user right bash script path
#It should be absolute
# 1st arg is the file editor user,
# 2nd argument is the web server/php-fpm group (which may need some write rights on specific places)
# 3rd argument CAN be DEV or empty
USER_RIGHTS="/srv/projects/foo/project/global-reset-perms.sh"

# Whether we are in dev mode or not...
# 
DEV_MODE="${DEV_MODE:-}"

# Used for account mail and site mail
MAIL="sysadmin@localhost"
NAME="admin"
PASS="password"

# values are 8 or anything else for previous versions
DRUPAL_VERSION=8
# "new_site" | "sync"
D8_INSTALL_MODE="new_site"

# Database info
DB_USER="sampledevu"
DB_PASS="sampledevp"
DB_TYPE="mysql"
# warning 'localhost' means socket, unavailable in chroot
DB_HOST="127.0.0.1"
DB_NAME="sampledev"
DB_PORT="3306"

SITE_NAME="SAMPLE"
SITE_MAIL="contact@localhost"
SITE_DEFAULT_COUNTRY="FR"

DATE_DEFAULT_TIMEZONE="Europe/Paris"
UPDATE_STATUS_MODULE=0

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
MODULES_CHECK="ctools webform token pathauto"

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
