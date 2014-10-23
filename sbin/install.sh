#!/bin/bash

# insall script for people not using saltctack to deploy

RED=$'\e[31;01m'
BLUE=$'\e[36;01m'
YELLOW=$'\e[33;01m'
NORMAL=$'\e[0m'

if [ "$1" = "make" ];
then
  #execute drush make
  ./"`dirname "$0"`/make.sh";
fi

#get some conf
. "`dirname "$0"`/get-paths.sh";
. "${BINPATH}/get-drush.sh";
. "${BINPATH}/profile_conf.sh";

#execute drush site-install
cd "${ROOTPATH}/www";

#store session informations if site already installed
SESSIONS="$(mktemp 'sessions_XXXXXXXXXX')"; trap 'rm "${SESSIONS}"' EXIT
test "`${DRUSH} st bootstrap --pipe --format=list`" == "Successful" && ${DRUSH} sql-dump --tables-list=sessions > "${SESSIONS}"

# re-add write rights for the directory in case of
chmod u+w ../sites/
chmod u+w ../sites/default

# Manually drop tables because drush site-install is an idiot
${DRUSH} sql-drop -y

${DRUSH} si -y "${PROFILE}" \
  --account-mail="${MAIL}" \
  --account-name="${NAME}" \
  --account-pass="${PASS}" \
  --db-url="${DB_TYPE}://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}" \
  --site-mail="${SITE_MAIL}" \
  --site-name="${SITE_NAME}" \
  --locale="${LOCALE}" \
  install_configure_form.site_default_country=FR \
  install_configure_form.date_default_timezone=Europe/Paris \
  install_configure_form.update_status_module=0

#restore sessions if they were saved
test -f "${SESSIONS}" && ${DRUSH} sqlc < "${SESSIONS}" && echo "Sessions restored"

# fix rights
${PATH_USER_RIGHTS}

# to add some post-install scripts, prefer writing some other sbin scripts and 
# laucnh them for here (this way we can add theses scripts in salt also
#${DRUSH} en devel_generate -y
#${DRUSH} dis devel_generate -y

${DRUSH} en field_ui -y

