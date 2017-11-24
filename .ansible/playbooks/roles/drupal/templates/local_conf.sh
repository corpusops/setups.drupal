#!/usr/bin/env bash
# {{ansible_managed}}
# {% set cfg = cops_drupal_vars %}
# {% set force = cfg.get('force', {}) %}

# Copy this file in the same directory
# and rename it to profile_conf.sh
# Enter property to used during drupal install

ROOTPATH="{{cfg.project_root}}"
BINPATH="{{cfg.project_root}}/sbin"
WWW_DIR="{{cfg.project_root}}/www"
DATA_DIR="{{cfg.data_root}}/var/sites"

# System User
USER="{{cfg.user}}"
GROUP="{{cfg.group}}"

MAIL="{{cfg.local_settings.account_email}}"
NAME="{{cfg.local_settings.account_name}}"
PASS="{{cfg.local_settings.site_password}}"
DB_HOST="{{cfg.db_host}}"
DB_NAME="{{cfg.db_name}}"
DB_PORT="{{cfg.db_port}}"
DB_USER="{{cfg.db_user}}"
DB_PASS="{{cfg.db_password}}"
DB_TYPE="{{cfg.db_type}}"
SITE_DEFAULT_COUNTRY="{{cfg.country}}"
DATE_DEFAULT_TIMEZONE="{{cfg.tz}}"
UPDATE_STATUS_MODULE="{{cfg.update_status_module}}"
SITE_NAME="{{cfg.local_settings.site_name}}"
SITE_MAIL="{{cfg.local_settings.site_email}}"

# drush make related
# Profile to use
PROFILE_NAME="{{cfg.drupal_profile}}"
DRUPAL_URI="{{cfg.drupal_uri}}"
DRUSH_EXTRA_ARGS="--uri="${DRUPAL_URI}""

# drush install related
FORCE_INSTALL_MARKER="{{cfg.data_root}}/force_install"
FORCE_INSTALL="{{force.get('install') and 'y' or ''}}"
INSTALL_MARKER="{{cfg.data_root}}/installed"

unset -v TARGETS
declare -A TARGETS
TARGETS["root@localhost"]="{{cfg.data_root}}/testsync"
# vim:set et sts=4 ts=4 tw=80:
