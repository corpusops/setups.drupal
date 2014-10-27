#!/bin/bash
# Project Deployment script
VERSION=1.0
EXPLAIN="Manage project deployment"
WHOAMI=`basename $0`;
USAGE="--${WHOAMI} : v${VERSION} --
${EXPLAIN}

Usage: ${WHOAMI} <ENV>

  ENV: required, value is either:
         DEV  : Developement environment
Check deploy.conf file, in the same directory as this file, for details
on file systems paths settings used depending on this ENV value.
"

# exit codes
END_SUCCESS=0;
END_FAIL=1;
END_RECVSIG=3;
END_BADUSAGE=65;

# some colors
RED=$'\e[31;01m'
BLUE=$'\e[36;01m'
YELLOW=$'\e[33;01m'
NORMAL=$'\e[0m'

# functions ##############
function bad_exit() {
        echo ;
        echo "${RED} ERROR: ${1}" >&2;
        echo "${NORMAL}" >&2;
        exit ${END_FAIL};
}

function ask() {
    UNDONE=1
    echo "${NORMAL}"
    while :
    do
            read -r -p " * ${1} (o/n): " USER_CHOICE
            if [ "x${USER_CHOICE}" == "xn" ]; then
              echo "${BLUE}  --> ok, step avoided.${NORMAL}"
              USER_CHOICE=abort
              break
            else
              if [ "x${USER_CHOICE}" == "xo" ]; then
                  USER_CHOICE=ok
                  break
              else
                  if [ "x${USER_CHOICE}" == "xy" ]; then
                      USER_CHOICE=ok
                      break
                  fi
              fi
            fi
            echo "${RED}Please answer \"o\",\"y\" (yes|oui) or \"n\" (no|non).${NORMAL}"
    done
}

function check_conf_arg {
    CONFARG=$1
    if [ "x${!CONFARG}" == "x" ]; then
        bad_exit "${CONFARG} is not defined in configuration file";
    fi

}


################################ MAIN

# Handle arguments #####
if [ $# -lt 1 ]
then
  echo "${USAGE}";
  echo ;
  echo "${RED}Error: bad number of arguments" >&2;
  echo "${NORMAL}" >&2;
  exit ${END_BADUSAGE};
fi

function check_directories() {
    # [g] -> versionés dans git
    # \- PROJECT_ROOT/
    #   [g] \-.salt/  <- pris dans corpus-salt
    #   [g]    \- files/ <- templates de fichiers de conf pour salt
    #   [g] \- sbin/     <- [no-salt]
    #   [g] \- config/   <- stockage de modèles de config client
    #   [g] \- www/      <-- DOC ROOT
    #   [g]     \- profiles/
    #   [g]         \- my_profile/
    #   [g]     \- sites/
    #   [g]        \-all/ <- possible de le mettre dans git
    #              \-default/  <-- symlink to [A]
    #   [g] \- sites/
    #         \- default/ <-- [A] in non-saltstack envs
    #             \- files/
    #       \- var/ <- [managed by salt or sbin script]
    #           \- fcgi/ <--- php-fpm socket (nginx<->php)
    #           \- tmp/
    #           \- log/
    #               \-php/
    #               \-nginx/
    #           \- private/
    WWWDIR=${PROJECT_PATH}/www
    SITESDIR=${WWWDIR}/sites
    VARDIR=${PROJECT_PATH}/var
    TMPDIR=${VARDIR}/tmp
    PRIVATEDIR=${VARDIR}/private
    LOGDIR=${VARDIR}/log
    SOCKETDIR=${VARDIR}/fcgi
    # only when not in salted environments, else it's ${PROJECT_PATH}/data
    DATADIR=${PROJECT_PATH}/sites
    # Create base directories if they do not exists
    if [ ! -d ${VARDIR} ]; then
        echo "${YELLOW}+ Creating ${VARDIR}${NORMAL}";
        mkdir -p  ${VARDIR};
    fi
    if [ ! -d ${TMPDIR} ]; then
        echo "${YELLOW}+ Creating ${TMPDIR}${NORMAL}";
        mkdir -p  ${TMPDIR};
    fi
    if [ ! -d ${LOGDIR} ]; then
        echo "${YELLOW}+ Creating ${LOGDIR}${NORMAL}";
        mkdir -p  ${LOGDIR};
    fi
    if [ ! -d ${PRIVATEDIR} ]; then
        echo "${YELLOW}+ Creating ${PRIVATEDIR}${NORMAL}";
        mkdir -p  ${PRIVATEDIR};
    fi
    if [ ! -d ${LOGDIR}/nginx ]; then
        echo "${YELLOW}+ Creating ${LOGDIR}/nginx${NORMAL}";
        mkdir -p  ${LOGDIR}/nginx;
    fi
    if [ ! -d ${LOGDIR}/php ]; then
        echo "${YELLOW}+ Creating ${LOGDIR}/php${NORMAL}";
        mkdir -p  ${LOGDIR}/php;
    fi
    if [ ! -d ${SOCKETDIR} ]; then
        echo "${YELLOW}+ Creating ${SOCKETDIR}${NORMAL}";
        mkdir -p  ${SOCKETDIR};
    fi
    if [ ! -d ${DATADIR} ]; then
        echo "${YELLOW}+ Creating ${DATADIR}${NORMAL}";
        mkdir -p  ${DATADIR};
    fi
    if [ ! -d ${DATADIR}/default ]; then
        echo "${YELLOW}+ Creating ${DATADIR}/default${NORMAL}";
        mkdir -p  ${DATADIR}/default;
    fi

    # Drupal specifics, in non salted envs, checks /www/sites/default
    # is really symbolic link to /sites/default directory
    if [ -e ${SITESDIR} ]; then
        if [ -d ${SITESDIR}/default ]; then
            if [ ! -h ${SITESDIR}/default ]; then
                echo "${YELLOW}+ ${SITESDIR}/default is a real directory!${NORMAL}";
                echo "${RED}++ moving it to ${SITESDIR}/default.bak!${NORMAL}";
                mv ${SITESDIR}/default ${SITESDIR}/default.bak
             fi
        fi
    else
        echo "${YELLOW}+ Creating ${SITESDIR}${NORMAL}";
        mkdir -p ${SITESDIR}
    fi
  
    echo "${YELLOW}+ Testing relative link ${SITESDIR}/default exists ${NORMAL}";
    if [ ! -h ${SITESDIR}/default ]; then
        echo "${YELLOW}++ No, so Creating relative symbolic link for ${DATADIR}/default ${SITESDIR}/default${NORMAL}";
        cd ${SITESDIR}
        echo "${YELLOW}++ Relative path used is: ../../sites/default ${NORMAL}";
        ln -s ../../sites/default default
        cd -
    fi
}


function install_dependencies() {
    echo "${YELLOW}+ apt-get install Dependencies (vim, unzip, sedi, tzdata)${NORMAL}"
    apt-get install vim \
      unzip \
      curl \
      wget \
      sed 
    echo "${YELLOW}We will launch tzselect, please choose the right timezone for your system (used by php-fpm)${NORMAL}"
    tzselect
}

function install_drush() {
  cd ${PROJECT_PATH}/sbin
  curl -sS https://getcomposer.org/installer | php
  composer install  
}

############## MAIN ####################

# Variables
cd "`dirname $0`";
BIN_DIR=`pwd`;
PROJECT_PATH=${BIN_DIR}"/..";
cd $PROJECT_PATH
PROJECT_PATH=`pwd`;
PROJECT_CONFIG_PATH=${PROJECT_PATH}/config;
BINDIR=${PROJECT_PATH}/sbin;
TARGET=$1;
minTARGET=`echo ${TARGET} | awk '{print tolower($0)}'`

if [ "$UID" -ne 0 ]; then
    bad_exit "User abort. Please run as root or with a sudo"
    read -r -p " * You are not running this script with sudo or as root. If your user account is not tweaked to get extended rights you may experience problems. Are you sure you want to run theses commands without a root account? (o/n): " USER_CHOICE
    if [ ! "x${USER_CHOICE}" == "xo" ]; then
        bad_exit "User abort. Please run as root or with a sudo"
    fi
fi

# LOAD CONFIGURATION
CONF=${BINDIR}/deploy.${minTARGET}.conf
if [ ! -e "${CONF}" ]; then
    bad_exit "Configuration file ${CONF} Not found!"
else
    echo "${YELLOW} * Loading configuration from ${CONF} ...${NORMAL}";
    . ${CONF}
fi

# CHECK CONF ###############
check_conf_arg "PROJECT_USER"
check_conf_arg "USER_RIGHTS"
check_conf_arg "SHORT"
check_conf_arg "DOMAIN"

# Check all the project directories are present, or create them!
check_directories

ask "0- Install Dependencies?"
if [ "x${USER_CHOICE}" == "xok" ]; then
    install_dependencies
fi

ask "1- Install composer and drush in sbin?"
if [ "x${USER_CHOICE}" == "xok" ]; then
    install_drush
fi


echo "${NORMAL}";
ask "- Reinit user rights?"
if [ "x${USER_CHOICE}" == "xok" ]; then
    chmod u+x ${BINDIR}/user_rights
    chmod u+x ${BINDIR}/drush
    chmod u+x ${BINDIR}/vendor/drush/drush/drush
    ask "Do you want to run project rights init script ${BINDIR}/user_rights with user/group as ${USER_RIGHTS}?"
    if [ "x${USER_CHOICE}" == "xok" ]; then
        echo "${YELLOW}${BINDIR}/user_rights ${USER_RIGHTS}"
        ${BINDIR}/user_rights ${USER_RIGHTS}
    fi
fi


echo "${YELLOW} * All jobs done!${NORMAL}"
echo "";
exit ${END_SUCCESS};
