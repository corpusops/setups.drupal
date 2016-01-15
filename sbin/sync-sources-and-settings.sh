#!/usr/bin/env bash
. "$(dirname ${0})/base.sh"
# Synchronize source files with rsync
VERSION=1.0
EXPLAIN="Synchronize Drupal source code and settings"
WHOAMI=(basename ${0})
USAGE="--${WHOAMI} : v${VERSION} --
${EXPLAIN}

Usage: ${WHOAMI} <ENV>

  ENV: required, value is either:
         DEV  : Developement environment
         PROD : Production environment

"
if [ ! -x "${RSYNC}" ];then
  bad_exit "rsync is needed, please run a sudo apt-get install rsync before."
fi
# commented as never called directly (from maj.sh)
if [ "x${USER_CHOICE}" != "xok" ]; then
    ask "$((${QUESTION++}))- Synchronize Drupal Sources (excluding settings and files)?"
fi
if [ "x${USER_CHOICE}" == "xok" ]; then
    rsync_www
fi 
echo "${NORMAL}"
echo "${YELLOW}Done...${NORMAL}";
