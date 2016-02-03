#!/usr/bin/env bash

# on first install you ll also have to have a look to override
# things on profile_conf.sh.example -> profile_conf.sh
# you can override any of those settings
# by creating and editing a file named
# local_conf.sh in this directory
RED=$'\e[31;01m'
BLUE=$'\e[36;01m'
YELLOW=$'\e[33;01m'
GREEN=$'\e[32;01m';
NORMAL=$'\e[0m'

# exit codes
END_SUCCESS=0
END_FAIL=1
END_RECVSIG=3
END_BADUSAGE=65
NONINTERACTIVE="${NONINTERACTIVE:-}"

# Whether we are in dev mode or not...
DEV_MODE="${DEV_MODE:-}"

function abspath() {
    python -c "import sys, os;sys.stdout.write(os.path.abspath(\"$@\"))"
}

# absolute path to "$dir/sbin" where
# there are our maintainance scripts
THIS_SCRIPT="${THIS_SCRIPT:-$(abspath "${0}")}"
BINPATH="$(echo "$THIS_SCRIPT"|sed -re "s/sbin\/.*/sbin/g")"
THE_DRUSH_WRAPPER="${BINPATH}/drush"
ROOTPATH="${ROOTPATH:-"$(cd "${BINPATH}" && cd .. && pwd)"}"
WWW_DIR="${WWW_DIR:-"${ROOTPATH}/www"}"
SITES_DIR="${SITES_DIR:-"${WWW_DIR}/sites"}"
PROJECT_CONFIG_PATH="${ROOTPATH}/sbin/templates"
# data dir (in salt/data_root) or $root/sites on non salt env.
DATA_DIR="${DATA_DIR:-"${ROOTPATH}/sites"}"
STOP_CRON_FLAG="${ROOTPATH}/var/tmp/suspend_drupal_cron_flag"
PRIVATE_PATH="${ROOTPATH}/var/private"
TMP_PATH="${ROOTPATH}/var/tmp"
SOCKET_PATH="${ROOTPATH}/var/fcgi"
CACHE_PATH="${ROOTPATH}/var/cache"
UPGRADES_MARKER="${BINPATH}/.upgrades.done"

# System User
USER="${USER:-$(whoami)}"
GROUP="${GROUP:-$(groups|awk '{print $0}')}"

# Locale to set
LOCALE="fr"

# drush make force markers
FORCE_MAKE="${FORCE_MAKE:-}"
# check for those module presence to force drush make
MODULES_CHECK="ctools webform token pathauto"
FORCE_MAKE_MARKER="${FORCE_MAKE_MARKER:-/a/non/existing/file}"

# drush install related
INSTALL_MARKER="${FORCE_INSTALL_MARKER:-/a/non/existing/file}"
FORCE_INSTALL_MARKER="${FORCE_INSTALL_MARKER:-/a/non/existing/file}"
FORCE_INSTALL="${FORCE_INSTALL:-}"

# override the drush profile asbsolute path
DRUPAL_PROFILE=""

# CODE SOURCE SYNC
SSH_PATH="${HOME}/.ssh/id_dsa"
RSYNC="$(which rsync)"
#unset -v TARGETS
#declare -A TARGETS
#TARGETS["root@localhost"]="/"

# drush preconfigured wrapper
LOCALCOMPOSER="${BINPATH}/composer.phar"
COMPOSER_URL="https://getcomposer.org/composer.phar"
COMPOSER_PRETENDANTS="${COMPOSER_PRETENDANTS} /usr/local/bin/composer"
COMPOSER_PRETENDANTS="${COMPOSER_PRETENDANTS} /usr/bin/composer"
COMPOSER_PRETENDANTS="${COMPOSER_PRETENDANTS} $(which composer 2>/dev/null)"
DRUSH="${BINPATH}/drush"
DRUSH_SPEC="drush/drush:6.*"
# drush bare script abs path
DRUSH_CMD="${DRUSH_CMD:-}"
# drush vare script search path if not found
DRUSH_PRETENDANTS="${DRUSH_PRETENDANTS:-"${ROOTPATH}/sbin/vendor/drush/drush/drush $(which drush) /usr/local/bin/drush /usr/bin/drush drush"}"
#DRUSH_EXTRA_ARGS="--include="${COMMAND_DIRS}" --uri="${DRUPAL_URI}""
DRUSH_CALL=""

function sync_src() {
    cd "${ROOTPATH}"
    echo "${YELLOW}+ Running ${ROOTPATH}/sbin/sync-sources-and-settings.sh${NORMAL}"
    # store choice for underlying script interaction
    export USER_CHOICE
    "${BINPATH}/sync-sources-and-settings.sh"
}

function settings_folder_write_fix() {
    cd "${ROOTPATH}"
    echo "${YELLOW}+ Check Write rights in ${ROOTPATH}/sites/default${NORMAL}"
    chmod u+w "${ROOTPATH}/sites/default"
    chown ${USER}:${GROUP} "${ROOTPATH}/sites/default"
}

function test_drush_status()  {
    call_drush status --format=yaml|grep -q "bootstrap: Successful"
    return $?
}

function git_checkout() {
    cd "${ROOTPATH}"
    echo "${YELLOW}+ git status${NORMAL}"
    git status
    echo "${YELLOW}+ git fetch --all${NORMAL}"
    git fetch --all
    echo "${YELLOW}+ git br${NORMAL}"
    git br
    read -r -p " * Which branch should we checkout in the previous list (answer should be something like something like 'stable 2.0.4': " GIT_BRANCH
    echo "${YELLOW}+ git checkout ${GIT_BRANCH}"
    git checkout ${GIT_BRANCH}
}

function filter_drush() {
    # Prevent fork bombs
    if [ "x${1}" != "x${THIS_SCRIPT}" ];then
        if [ "x${1}" != "x${THE_DRUSH_WRAPPER}" ];then
            echo "${1}"
        fi
    fi
}

function install_drush() {
    cd "${BINPATH}"
    call_composer require "${DRUSH_SPEC}"
}

function set_drush() {
    norec=""
    for i in ${@};do
        if [ "x${i}" = "xnorec" ];then
            norec="1"
        fi
    done
    if [ "x${DRUSH_CALL}" = "x" ];then
        search=""
        if [ ! -x "${DRUSH_CMD}" ];then
            search="y"
        fi
        if [ "x${search}" != "x" ];then
            for i in ${DRUSH_PRETENDANTS};do
                if [ -x "$(filter_drush ${i})" ];then
                    if ${i} --version 1>/dev/null 2>&1;then
                        DRUSH_CMD="${i}"
                        break
                    fi
                fi
            done
        fi
        if [ ! -x "${DRUSH_CMD}" ];then
            install_drush
        else
            # we didnt install, no chance to refind it on
            # next call
            norec=""
        fi
        if [ ! -x "${DRUSH_CMD}" ];then
            # if not found but installed, try to find the cmd
            if [ "x${norec}" = "x" ];then
                set_drush norec
            else
                echo "no drush"
                exit 1
            fi
        fi
        DRUSH_CALL="${DRUSH_CMD} --root="${WWW_DIR}" ${DRUSH_EXTRA_ARGS}"
    fi
}

function bad_exit() {
        echo ;
        echo "${RED} ERROR: ${1}" >&2;
        echo "${NORMAL}" >&2;
        exit ${END_FAIL};
}

function check_conf_arg() {
    CONFARG=${1}
    if [ "x${!CONFARG}" == "x" ]; then
        bad_exit "${CONFARG} is not defined in configuration file"
    fi
}

function ask() {
    UNDONE=1
    echo "${NORMAL}"
    while :
    do
        read -r -p " * ${1} [o/n]: " USER_CHOICE
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

function replace_in_file() {
  TAG=$1
  # VALUE variable must contain escaped commas
  VALUE=${2//,/\\,}
  FILE=$3
  # this is a
  # sed -u 's, __FOO_BAR___, my value,g /in/this/file
  echo "${YELLOW}   * ${FILE} : __${TAG}__ => ${GREEN}${VALUE}${NORMAL}"
  sed -i 's,__'"${TAG}"'__,'"${VALUE}"',g' "${FILE}"
}

function replace_in_salt_file() {
  TAG=$1
  # VALUE variable must contain escaped commas
  VALUE=${2//,/\\,}
  FILE=$3
  # this is a
  # sed -u 's, {{ FOO_BAR }}, my value,g /in/this/file
  echo "${YELLOW}   * ${FILE} : {{${TAG}}} => ${GREEN}${VALUE}${NORMAL}"
  sed -i 's,{{'"${TAG}"'}},'"${VALUE}"',g' "${FILE}"
}

function backup_settings() {
    cd "${ROOTPATH}"
    NOW="$(date +"%Y-%m-%d-%S")"
    if [ ! -d ../backups ]; then
        mkdir ../backups
    fi
    echo "${YELLOW}+ backup settings.php in ../backups/settings.php.${NOW} ${NORMAL}"
    cp sites/default/settings.php "../backups/settings.php.${NOW}";
    echo "${YELLOW}+ backup local.settings.php in ../backups/local.settings.php.${NOW} ${NORMAL}"
    cp sites/default/local.settings.php "../backups/local.settings.php.${NOW}";
}

download() {
    url="${1}"
    target="${2}"
    shift
    shift
    if which curl >/dev/null 2>&1;then
        curl -sS "${url}" -o "${target}"
    elif which wget >/dev/null 2>&1;then
        wget --quiet ${@} "${url}" -O "${target}"
    else
        echo "no download method available"
        exit 1
    fi

}

COMPOSER_SET=""
function set_composer() {
    if [ "x${COMPOSER_SET}" = "x" ];then
        composer=""
        for c in ${COMPOSER_PRETENDANTS};do
            if [ -x "${c}" ];then
                if "${c}" --version 1>/dev/null 2>&1;then
                    composer="${c}"
                    break
                fi
            fi
        done
        FORCE_LOCAL_COMPOSER="${FORCE_LOCAL_COMPOSER:-}"
        if [ "x${composer}" = "x" ];then
            FORCE_LOCAL_COMPOSER="y"
        fi
        if [ "x${FORCE_LOCAL_COMPOSER}" != "x" ];then
            download="1"
            if [ -e "${LOCALCOMPOSER}" ];then
                chmod +x "${LOCALCOMPOSER}"
                if "${LOCALCOMPOSER}" --version >/dev/null 2>&1;then
                    download=""
                fi
            fi
            if [ "x${download}" != "x" ];then
                download "${COMPOSER_URL}" "${LOCALCOMPOSER}"
                chmod +x "${LOCALCOMPOSER}"
            fi
            composer="${LOCALCOMPOSER}"
        fi
        COMPOSER_SET=${composer}
    fi
}

function call_composer() {
    set_composer
    "${COMPOSER_SET}" "${@}"
}

function call_drush() {
    set_drush
    # Always cd in drupal www dir before running drush !
    cwd="$(pwd)"
    cd "${WWW_DIR}"
    ${DRUSH_CALL} "${@}"
    cd "${cwd}"
}

function verbose_call_drush() {
    echo "${YELLOW}+ drush ${@}${NORMAL}"
    call_drush "${@}"
}

function site_modules_dir() {
    echo "${WWW_DIR}/sites/all/modules"
}

function drupal_profile() {
    echo "${DRUPAL_PROFILE:-"${WWW_DIR}/profiles/${PROJECT_NAME}/${PROJECT_NAME}.make"}"
}

function suspend_cron() {
    echo "${YELLOW}+ touch ${STOP_CRON_FLAG}${NORMAL}"
    touch "${STOP_CRON_FLAG}"
}

function unsuspend_cron() {
    echo "${YELLOW}+ rm -f  ${STOP_CRON_FLAG}${NORMAL}"
    rm -f "${STOP_CRON_FLAG}"
}

function maintenance_mode() {
    echo "${YELLOW}+ drush vset maintenance_mode 1${NORMAL}"
    ${BINPATH}/drush vset maintenance_mode 1
}

function undo_maintenance_mode() {
    echo "${YELLOW}+ drush vset maintenance_mode 0${NORMAL}"
    ${BINPATH}/drush vset maintenance_mode 0
}

function activate_maintenance() {
    maintenance_mode
    suspend_cron
}

function deactivate_maintenance() {
    undo_maintenance_mode
    unsuspend_cron
}

function drush_updb() {
    verbose_call_drush -y updb
}

function drush_fra() {
    verbose_call_drush -y fr-all
}

function drush_cc_all() {
    verbose_call_drush -y cc all
}

function do_sync() {
    dest="$(basename ${1})"
    fdest="${1}"
    ftarget="${2}"
    shift
    shift
    echo "${YELLOW}== now Rsync ${dest}...${NORMAL}"
    "${RSYNC}" -e 'ssh -i "${SSH_PATH}"' -av --stats --del --ignore-errors --force ${@} "${fdest}" "${ftarget}"
}

function die() {
    echo "$@"
    exit 1
}

function has_db() {
    NBTABLES="$(${DRUSH} sqlq "SHOW TABLES" | wc -l | sed -e "s/ //g")"
    test "${NBTABLES}" -gt "25"
}

function rsync_www() {
    # WARNING: never sync ${ROOTPATH}/sites/default/files and ${ROOTPATH}/var
    # Also fake a git sync status between front servers
    # End with real sources
    unset SYNC_DIRS
    declare -A SYNC_DIRS
    # values of the array are excluded paths
    SYNC_DIRS["${WWW_DIR}/"]="sites/default/files"
    SYNC_DIRS["${DATA_DIR}/"]="default/files"
    for TARGET in "${!TARGETS[@]}";do
        pref=${TARGETS[${TARGET}]}
        if [ "x${pref}" = "x" ];then
            pref="/"
        fi
        for fdest in .gitignore docs/ lib/ sbin/ tests/ mailing/ .git/;do
            dest="${ROOTPATH}/${fdest}"
            do_sync "${dest}" "${TARGET}:${pref}${dest}"
        done
        for dest in "${!SYNC_DIRS[@]}";do
            exclude="${SYNC_DIRS[${dest}]}"
            do_sync "${dest}" "${TARGET}:${pref}${dest}" --exclude "${exclude}"
        done
    done
}

function check_default_symlink() {
    cd "${ROOTPATH}"
    if [ ! -d "${DATA_DIR}/default" ]; then
        echo "${YELLOW}+ Creating ${DATA_DIR}/default${NORMAL}";
        mkdir -p  "${DATA_DIR}/default"
    fi
    # Drupal specifics, in non salted envs, checks /www/sites/default
    # is really symbolic link to /sites/default directory
    if [ -e "${SITES_DIR}" ]; then
        if [ -d "${SITES_DIR}/default" ]; then
            if [ ! -h "${SITES_DIR}/default" ]; then
                echo "${YELLOW}+ ${SITES_DIR}/default is a real directory!${NORMAL}"
                echo "${RED}++ moving it to ${SITES_DIR}/default.bak!${NORMAL}"
                mv "${SITES_DIR}/default" "${SITES_DIR}/default.bak"
            fi
        fi
    else
        echo "${YELLOW}+ Creating ${SITES_DIR}${NORMAL}"
        mkdir -p "${SITES_DIR}"
    fi

    echo "${YELLOW}+ Testing relative link ${SITES_DIR}/default exists ${NORMAL}"
    if [ ! -h ${SITES_DIR}/default ]; then
        echo "${YELLOW}++ No, so Creating relative symbolic link for ${DATA_DIR}/default ${SITES_DIR}/default${NORMAL}";
        cd "${SITES_DIR}"
        echo "${YELLOW}++ Relative path used is: ../../sites/default ${NORMAL}"
        ln -s ../../sites/default default
        cd -
    fi
    if [ ! -d ${SITES_DIR}/default/files ]; then
        echo "${YELLOW}+ Creating ${SITES_DIR}/default/files for better default rights ${NORMAL}";
        mkdir "${SITES_DIR}/default/files"
    fi
}

function default_user_rights() {
    USER_RIGHTS="${BINPATH}/user_rights ${USER} ${GROUP}"
    if  [ "${DEV_MODE}" != "x" ];then
        USER_RIGHTS="${USER_RIGHTS} DEV"
    fi
    echo "${USER_RIGHTS}"
}

# LOAD USER DEFINED VARS and OVERRIDEN FUNCTIONS !!!
ENV_SET=""
#  override any environment settings via local shell files
for i in "${BINPATH}/local_conf.sh";do
    if [ -e "${i}" ];then
        . "${i}"
        ENV_SET="1"
    fi
done
# overriding (even just touching a settings file) is mandatory
# to ensure that user has configured his environment
if [ "x${ENV_SET}" = "x" ];then
    echo "no custom settings found, environment is not configured"
    echo "create (even empty) ${BINPATH}/local_conf.sh"
    exit 1
fi

# POST PROCESS SOME VARIABLES
# disabling user_rights is by setting USER_RIGHTS=no
# user right bash script path
# It should be absolute
# 1st arg is the file editor user,
# 2nd argument is the web server/php-fpm group (which may need some write rights on specific places)
# 3rd argument CAN be DEV or empty
if [ "x${USER_RIGHTS}" = "xno" ];then
    USER_RIGHTS=""
elif [ "x${USER_RIGHTS}" = "x" ];then
    USER_RIGHTS=$(default_user_rights)
fi
DEVMODE="${DEV_MODE}"
# vim:set et sts=4 ts=4 tw=80:
