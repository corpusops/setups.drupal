#!/usr/bin/env bash
# MANAGED VIA SALT !
# {% set cfg = salt['mc_project.get_configuration'](cfg) %}
# {% set data = cfg.data %}
# {% set force = data.get('force', {}) %}
# . "$(dirname ${0})/get-base.sh"
# Locale to set
LOCALE="{{data.drupal_locale}}"

# Used for account mail and site mail
MAIL="{{data.local_settings.account_email}}"
NAME="{{data.local_settings.account_name}}"
PASS="{{data.local_settings.site_password}}"

# Database info
# warning 'localhost' means socket, unavailable in chroot
DB_HOST="{{data.db_host}}"
DB_NAME="{{data.db_name}}"
DB_PORT="{{data.db_port}}"
DB_USER="{{data.db_user}}"
DB_PASS="{{data.db_password}}"
DB_TYPE="mysql"

SITE_DEFAULT_COUNTRY="{{data.country}}"
DATE_DEFAULT_TIMEZONE="{{data.tz}}"
UPDATE_STATUS_MODULE="{{data.update_status_module}}"

SITE_NAME="{{data.local_settings.site_name}}"
SITE_MAIL="{{data.local_settings.site_email}}"
# vim:set et sts=4 ts=4 tw=80:
