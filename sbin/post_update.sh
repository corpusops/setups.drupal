#!/usr/bin/env bash
# Project Deployment script
QUESTION=0
VERSION=2.0
EXPLAIN="Manage project deployment"
WHOAMI=`basename $0`;
USAGE="--${WHOAMI} : v${VERSION} --
${EXPLAIN}

Usage: [ASK=yauto] ${WHOAMI}

"

. "$(dirname "${0}")/base.sh"

check_default_symlink

ask "$((QUESTION++))- Do you want to run a drush -y updb ?"
if [ "xok" = "x${USER_CHOICE}" ]; then
    echo "${YELLOW}  - So we run drush -y updb${NORMAL}"
    call_drush -y updb
fi

# TODO: regilero check d8
# echo
# echo "${YELLOW}check if acl rebuild is needed...${NORMAL}"
# RES=`call_drush vget node_access_needs_rebuild`
# if [ "xnode_access_needs_rebuild: 1" == "x${RES}" ] || [ "xnode_access_needs_rebuild: true" == "x${RES}" ]; then
#     echo "${YELLOW}...yes${NORMAL}"
#     call_drush -y node-access-rebuild
#     call_drush vset node_access_needs_rebuild 0
# else
#     echo "${YELLOW}...no${NORMAL}"
# fi

ask "$((QUESTION++))- Do you want to run a drush -y cim ?"
if [ "xok" = "x${USER_CHOICE}" ]; then
    echo "${YELLOW}  - So we run drush -y cim${NORMAL}"
    verbose_call_drush -y cim
fi

ask "$((QUESTION++))- Clear all caches via drush ?"
if [ "x${USER_CHOICE}" = "xok" ]; then
   drush_cr
fi
echo "${NORMAL}"

exit ${END_SUCCESS}
