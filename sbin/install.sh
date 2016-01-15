#!/usr/bin/env bash
# install script for people not using saltstack to deploy
. "$(dirname "${0}")/base.sh"
SETTINGS="${BINPATH}/profile_conf.sh"
if [ ! -e "${SETTINGS}" ];then
    echo "${SETTINGS} does not exists, create it from ${SETTINGS}.example or ${SETTINGS}.prod"
    exit 1
fi

. "${SETTINGS}"

# if installation was never done,
# we will certainly have less than 10 tables in datase
NB_TABLES=$(call_drush sqlq --extra="-N" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}';" 2>/dev/null)
if [ "${NB_TABLES}" -lt "10" ];then
    do_install="y"
else
    do_install=""
fi

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
PROFILE_PATH="$(dirname "${PROFILE}")"
PROFILE_NAME="$(basename "${PROFILE_PATH}")"

# remove www/robots.txt (IF this site use a module for that url)
#if [ -e "${ROOTPATH}/www/robots.txt" ];then
#    rm "${ROOTPATH}/www/robots.txt"
#fi

#store session informations if site already installed
SESSIONS="$(mktemp 'sessions_XXXXXXXXXX')"
trap 'rm "${SESSIONS}"' EXIT
test "x$(call_drush st bootstrap --pipe --format=list)" = "xSuccessful" && call_drush sql-dump --tables-list=sessions > "${SESSIONS}"

# re-add write rights for the directory in case of
chmod u+w "${SITES_DIR}" "${SITES_DIR}/default"

cd "${WWW_DIR}"

# Manually drop tables because drush site-install is an idiot
call_drush sql-drop -y

cd "${WWW_DIR}"

DRUPAL_VERSION="$(call_drush status|grep "Drupal version"|cut -d: -f2| tr -d '[:space:]')"

cd "${WWW_DIR}"
if [ "x${DRUPAL_VERSION}" = "x8" ]; then
    # Drupal 8 install
    verbose_call_drush si -v -y "${PROFILE_NAME}" \
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
else
    # D7 or older install mode (default)
    verbose_call_drush si -v -y "${PROFILE_NAME}" \
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
fi

# download locale
DRUPAL_VERSION="$(call_drush status|grep "Drupal version"|cut -d: -f2| tr -d '[:space:]')"
echo $DRUPAL_VERSION
if [ "x${DRUPAL_VERSION}" = "x" ];then
    echo  "cant install locale, unknown version, the site may have failed to install"
    exit 1
fi
if [ ! -f ${PROFILE_PATH}/translations/drupal-"${DRUPAL_VERSION}".${LOCALE}.po ]; then
    wget "http://ftp.drupal.org/files/translations/7.x/drupal/drupal-"${DRUPAL_VERSION}".${LOCALE}.po" -P ${PROFILE_PATH}/translations/
    if [ "x${?}" != "x0" ];then
        echo "Locale ${LOCALE} failed to download"
        exit 1
    fi
fi

#restore sessions if they were saved
test -f "${SESSIONS}" && call_drush sqlc < "${SESSIONS}" && echo "Sessions restored"

# fix rights
if [ "x${USER_RIGHTS}" != "x" ];then
    echo "running "${USER_RIGHTS}""
fi

# Enable some dev modules.
if [ "x${DEV_MODE}" = "x1" ];then
    call_drush en field_ui -y
fi
