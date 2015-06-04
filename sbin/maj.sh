#!/usr/bin/env bash
# Project Deployment script
VERSION=2.0
EXPLAIN="Manage project deployment"
WHOAMI=`basename $0`;
USAGE="--${WHOAMI} : v${VERSION} --
${EXPLAIN}

Usage: ${WHOAMI} <ENV>

  ENV: required, value is either:
         DEV  : Developement environment
         PROD : Production environment

"

. "$(dirname ${0})/base.sh"

check_default_symlink

QUESTION=0
ask "$((QUESTION++))- Backup settings ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    set -x
    settings_folder_write_fix
    backup_settings
fi
echo "${NORMAL}"

ask "$((QUESTION++))- suspend Cron tasks on all servers ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    suspend_cron
fi
echo "${NORMAL}"

ask "$((QUESTION++))- set Maintenance mode via drush variable-set (So, on ALL SERVERS)?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    maintenance_mode
fi
echo "${NORMAL}"

ask "$((QUESTION++))- git fetch/checkout/etc ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    settings_folder_write_fix
    git_checkout
fi
echo "${NORMAL}"

ask "$((QUESTION++))- Synchronize source from master to slave ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
   sync_src
fi
echo "${NORMAL}"

ask "$((QUESTION++))- Apply drush update-db ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
   drush_updb
fi
echo "${NORMAL}"

ask "$((QUESTION++))- Apply drush Feature revert 'All' ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
   drush_fra
fi
echo "${NORMAL}"

ask "$((QUESTION++))- Reinit user rights (at least the one I can re-init with this user) ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    chmod u+x ${BINPATH}/user_rights
    chmod u+x ${BINPATH}/drush
    chmod u+x ${BINPATH}/vendor/drush/drush/drush
    ask "Do you want to run project rights fix  script"
    echo "${USER_RIGHTS}"
    if [ "x${USER_CHOICE}" = "xok" ]; then
        settings_folder_write_fix
        if [ "x${USER_RIGHTS}" != "x" ];then
            ${USER_RIGHTS}
        fi
    fi
fi

ask "$((QUESTION++))- Remove maintenance via drush variable-set ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    undo_maintenance_mode
fi
echo "${NORMAL}"

ask "$((QUESTION++))- Clear all caches via drush ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
   drush_cc_all
fi
echo "${NORMAL}"

ask "$((QUESTION++))- Restore Cron tasks on all servers ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    unsuspend_cron
fi
echo "${NORMAL}"

ask "$((QUESTION++))- Would you like to launch planified upgrades ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
    "${BINPATH}/upgrade.sh"
fi
echo "${NORMAL}"

exit ${END_SUCCESS}
