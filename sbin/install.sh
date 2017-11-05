#!/usr/bin/env bash
. "$(dirname "${0}")/base.sh"

cd "${WWW_DIR}" || die "no $WWW_DIR"

# test mysql availability
if ! call_drush sqlq "SELECT 'TEST_DB_CONN'" 2>&1 | egrep -q "^TEST_DB_CONN$";then
    echo "DB server is not available"
    exit 1
fi

# if installation was never done,
# we will certainly have less than 10 tables in datase
do_install=""
if ! has_ignited_db;then
    do_install="y"
fi

if [ "x${FORCE_INSTALL}" != "x0" ] && [ "x${FORCE_INSTALL}" != "x" ];then
    do_install="y"
elif [ -e "${FORCE_INSTALL_MARKER}" ];then
    do_install="y"
elif [ -e "${INSTALL_MARKER}" ];then
    do_install=""
fi

if [ "x${do_install}" = "x" ];then
    log "Install skipped"
    exit 0
fi

PROFILE="$(drupal_profile)"
PROFILE_PATH="$(dirname "${PROFILE}")"
PROFILE_NAME="$(basename "${PROFILE_PATH}")"

# remove www/robots.txt (IF this site use a module for that url)
# if [ -e "${ROOTPATH}/www/robots.txt" ];then
#     rm "${ROOTPATH}/www/robots.txt"
# fi

# Manually drop tables because drush site-install is an idiot
call_drush sql-drop -y

# First install (no exported conf), use the real profile
chmod u+rwx "${WWW_DIR}/sites/default"
chmod u+rw "${WWW_DIR}/sites/default/settings.php"
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
config_installer_sync_configure_form.sync_directory="${DRUPAL_CONFIG_PATH}"
ret=$?
exit $ret
