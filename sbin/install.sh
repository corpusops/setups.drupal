#!/usr/bin/env bash
# install script for people not using saltstack to deploy
. "$(dirname "${0}")/base.sh"
SETTINGS="${BINPATH}/profile_conf.sh"
if [ ! -e "${SETTINGS}" ];then
    echo "${SETTINGS} does not exists, create it from ${SETTINGS}.sample"
    exit 1
fi

. "${SETTINGS}"


do_install=""
if [ "x${FORCE_INSTALL}" != "x0" ] && [ "x${FORCE_INSTALL}" != "x" ];then
    do_install="y"
elif [ -e "${FORCE_INSTALL_MARKER}" ];then
    do_install="y"
elif [ -e "${INSTALL_MARKER}" ];then
    do_install=""
fi

if [ "x${do_install}" = "x" ];then
    echo "Install skipped"
    exit 0
fi

if [ "x${1}" = "xmake" ];then
    # execute drush make
    "${BINPATH}/make.sh"
    ret="${?}"
    if [ "x${ret}" != "x0" ];then
        echo "Make failed"
        exit ${ret}
    fi
fi

cd "${WWW_DIR}"
PROFILE="$(drupal_profile)"
PROFILE_PATH="$(dirname "${PROFILE_PATH}")"

# remove www/robots.txt (this site use a module for that url)
rm "${ROOTPATH}/www/robots.txt"

#store session informations if site already installed
SESSIONS="$(mktemp 'sessions_XXXXXXXXXX')"
trap 'rm "${SESSIONS}"' EXIT
test "x$(call_drush st bootstrap --pipe --format=list)" = "xSuccessful" && call_drush sql-dump --tables-list=sessions > "${SESSIONS}"

# re-add write rights for the directory in case of
chmod u+w ../sites/
chmod u+w ../sites/default

# download locale
VERSION=$(call_drush status|grep "Drupal version"|cut -d: -f2| tr -d '[:space:]')
if [ ! -f ${PROFILE_PATH}/translations/drupal-$VERSION.${LOCALE}.po ]; then
    wget "http://ftp.drupal.org/files/translations/7.x/drupal/drupal-$VERSION.${LOCALE}.po" -P ${PROFILE_PATH}/translations/
fi

cd "${WWW_DIR}"

# Manually drop tables because drush site-install is an idiot
call_drush sql-drop -y

cd "${WWW_DIR}"

# Remove translations while installing... arf, @see https://www.drupal.org/node/1297438
if [ -d "${PROFILE_PATH}/translations" ];then
    mv "${PROFILE_PATH}/translations" "${PROFILE_PATH}/translations_back"
fi

call_drush si -v -y "${PROFILE}" \
  --account-mail="${MAIL}" \
  --account-name="${NAME}" \
  --account-pass="${PASS}" \
  --db-url="${DB_TYPE}://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}" \
  --site-mail="${SITE_MAIL}" \
  --site-name="${SITE_NAME}" \
  --locale="${LOCALE}" \
  install_configure_form.site_default_country=${SITE_DEFAULT_COUNTRY} \
  install_configure_form.date_default_timezone=${DATE_DEFAULT_TIMEZONE} \
  install_configure_form.update_status_module=${UPDATE_STATUS_MODULE} \
  --debug ${EXTRA_DRUSH_SITE_INSTALL_ARGS} 

# restore translations
if [ -d "${PROFILE_PATH}/translations_back" ];then
    mv "${PROFILE_PATH}/translations_back" "${PROFILE_PATH}/translations"
fi

#restore sessions if they were saved
test -f "${SESSIONS}" && call_drush sqlc < "${SESSIONS}" && echo "Sessions restored"

# fix rights
if [ "x${USER_RIGHTS}" != "x" ];then
    "${USER_RIGHTS}"
fi

# Enable some dev modules.
if [ "x${DEV_MODE}" = "x1" ];then
    call_drush en field_ui -y
fi
