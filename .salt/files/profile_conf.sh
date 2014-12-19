#!/bin/sh
# MANAGED VIA SALT !
{% set cfg = salt['mc_project.get_configuration'](project) %}
{% set data = cfg.data %}

#Copy this file in the same directory
#and rename it to profile_conf.sh

#Enter property to used during drupal install

# Locale to set
LOCALE="{{data.drupal_locale}}"

# Profile to use
PROFILE="{{cfg.name}}"

# System User
USER="{{cfg.user}}"

# Used for account mail and site mail
MAIL="{{data.local_settings.account_email}}"
NAME="{[data.local_settings.account_name}}"
PASS="{{data.local_settings.site_password}}"

# Database info
DB_USER="{{data.db_user}}"
DB_PASS="{{data.db_password}}"
DB_TYPE="mysql"
# warning 'localhost' means socket, unavailable in chroot
DB_HOST="{{data.db_host}}"
DB_NAME="{{data.db_name}}"
DB_PORT="{{data.db_port}}}}"

SITE_NAME="{{data.local_settings.site_name}}"
SITE_MAIL="{{data.local_settings.site_email}}"

#user right bash script path
#It should be absolute
# 1st arg is the file editor user,
# 2nd argument is the web server/php-fpm group (which may need some write rights on specific places)
# 3rd argument CAN be DEV or empty
USER_RIGHTS=""

# Whether we are in dev mode or not...
{% set devmode = cfg.default_env in ['dev'] and '1' or '' %}
DEV_MODE="${DEV_MODE:-{{devmode}}}"
# vim:set et sts=4 ts=4 tw=80:
