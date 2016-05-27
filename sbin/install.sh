#!/usr/bin/env bash
# main install script
# Note that you may need to populate local_conf.sh via
# the 100_app.sls salt treatment to feed the real values
# of variables (and not the ones from basE.sh)
. "$(dirname "${0}")/base.sh"

# test mysql availability
if ! call_drush sqlq "SELECT 'TEST_MYSQL_CONN'" 2>&1 | egrep -q "^TEST_MYSQL_CONN$"; then
    echo "Mysql server is not available"
    exit 1
fi

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

if [ "x${DRUPAL_VERSION}" = "x8" ]; then
    # Drupal 8 install
    # @see PILLAR.sample to set this to 'new_site' if you are the 1st player
    # else you will have to sync your conf with the 1st installed website
    # Pillar goes to local_conf.sh which set this varaiable
    # D8_INSTALL_MODE="new_website"|"sync"
    if [ "x${D8_INSTALL_MODE}" = "xnew_website" ]; then
        # First install (no exported conf), use the real profile
        verbose_call_drush site-install -v -y "${PROFILE_NAME}" \
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
        # use config installer to sync conf from a previously installed website
        # This is currently "In test"
        # Seems we need to install a minimal profile first (and then call a second drush si). But maybe not.
        # Currently everything is failing badly : https://www.drupal.org/node/2658912
        #chmod u+rwx "${WWW_DIR}/sites/default"
        #chmod u+rw "${WWW_DIR}/sites/default/settings.php"
        #verbose_call_drush site-install -v -y "minimal" \
        #  --account-mail="${MAIL}" \
        #  --account-name="${NAME}" \
        #  --account-pass="${PASS}" \
        #  --db-url="${DB_TYPE}://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}" \
        #  --site-mail="${SITE_MAIL}" \
        #  --site-name="${SITE_NAME}" \
        #  --locale="${LOCALE}" \
        #  install_configure_form.site_default_country=${SITE_DEFAULT_COUNTRY} \
        #  install_configure_form.date_default_timezone=${DATE_DEFAULT_TIMEZONE} \
        #  install_configure_form.update_status_module=${UPDATE_STATUS_MODULE} \
        #  --debug ${EXTRA_DRUSH_SITE_INSTALL_ARGS}
        chmod u+rwx "${WWW_DIR}/sites/default"
        chmod u+rw "${WWW_DIR}/sites/default/settings.php"
        #ls -alh ${WWW_DIR}/sites/default
        # verbose_call_drush language-add fr
        # verbose_call_drush language-enable fr
        #  --keep-config
        verbose_call_drush site-install -v -y "config_installer" \
          --account-mail="${MAIL}" \
          --account-name="${NAME}" \
          --account-pass="${PASS}" \
          --db-url="${DB_TYPE}://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}" \
          --site-mail="${SITE_MAIL}" \
          --site-name="${SITE_NAME}" \
          --locale="${LOCALE}" \
          config_installer_sync_configure_form.sync_directory="${DRUPAL_CONFIG_PATH}" \
          config_installer_site_configure_form.account.name="${NAME}" \
          config_installer_site_configure_form.account.pass.pass1="${PASS}" \
          config_installer_site_configure_form.account.pass.pass2="${PASS}" \
          config_installer_site_configure_form.account.mail="${MAIL}" \
          --debug ${EXTRA_DRUSH_SITE_INSTALL_ARGS}
    fi
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
