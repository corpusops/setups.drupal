#!/usr/bin/env bash
# If you azre not using ansible or a tool that generate local_conf.sh
# Copy this file in the same directory and rename it to local_conf.sh

# System User (also set inside base.sh)
# USER="foo-user"
# GROUP="foo-grp"

MAIL="sysadmin@localhost"
NAME="admin"
PASS="password"
DB_USER="sampledevu"
DB_PASS="sampledevp"
DB_TYPE="mysql"
DB_HOST="127.0.0.1"
DB_NAME="sampledev"
DB_PORT="3306"

SITE_NAME="SAMPLE"
SITE_MAIL="contact@localhost"
SITE_DEFAULT_COUNTRY="FR"
DATE_DEFAULT_TIMEZONE="Europe/Paris"
UPDATE_STATUS_MODULE=0

# drush make related
# Profile to use
PROJECT_NAME="${PROJECT_NAME}"
DRUPAL_URI="http://${PROJECT_NAME}.local"
DRUSH_EXTRA_ARGS="--uri="${DRUPAL_URI}""

# drush install related
FORCE_INSTALL_MARKER="${DATA_DIR}/force_install"
INSTALL_MARKER="${DATA_DIR}/installed"
FORCE_INSTALL=""

# rsync settings between envs
unset -v TARGETS
declare -A TARGETS
TARGETS["root@localhost"]="${DATA_DIR}/testsync"
# vim:set et sts=4 ts=4 tw=80:
