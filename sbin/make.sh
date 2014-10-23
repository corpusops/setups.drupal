#!/bin/bash

. "`dirname "$0"`/get-paths.sh";
. "${BINPATH}/get-drush.sh";
. "${BINPATH}/profile_conf.sh";

cd "${ROOTPATH}/www";
chmod u+w ${ROOTPATH}/www/sites/*
echo "${DRUSH} make --concurrency=4 -y \"${BINPATH}/../www/profiles/${PROFILE}/${PROFILE}.make\""
${DRUSH} make --concurrency=4 -y "${BINPATH}/../www/profiles/${PROFILE}/${PROFILE}.make";

