#!/usr/bin/env bash
# This is the main bash ressource file.
#  - defautl variables values
#  - fonctions used by others
# Do NOT ALTER this file.
# INSTEAD check local_conf.sh in same directory
# Note that local_conf.sh is populated by the
# .salt/100_app.sls salt function, using .salt/PILLAR.sample
# and the local pillar.

shopt -s extglob

RED=$'\e[31;01m'
BLUE=$'\e[36;01m'
YELLOW=$'\e[33;01m'
GREEN=$'\e[32;01m';
NORMAL=$'\e[0m'
CYAN="\\e[0;36m"

# exit codes
END_SUCCESS=0
END_FAIL=1
END_RECVSIG=3
END_BADUSAGE=65
NONINTERACTIVE="${NONINTERACTIVE:-}"

abspath() {
    python -c "import sys, os;sys.stdout.write(os.path.abspath(\"$@\"))"
}

# absolute path to "$dir/sbin" where
# there are our maintainance scripts
THIS_SCRIPT="${THIS_SCRIPT:-$(abspath "${0}")}"
BINPATH="$(echo "$THIS_SCRIPT"|sed -re "s/sbin\/.*/sbin/g")"
ROOTPATH="${ROOTPATH:-"$(cd "${BINPATH}" && cd .. && pwd)"}"
WWW_DIR="${WWW_DIR:-"${ROOTPATH}/www"}"
SITES_DIR="${SITES_DIR:-"${WWW_DIR}/sites"}"
SITES_SUBDIR="${SITES_SUBDIR:-"default"}"
#DRUPAL_CONFIG_PATH="${ROOTPATH}/lib/config/sync"
# data dir (in salt/data_root) or $root/sites on non salt env.
DATA_DIR="${DATA_DIR:-"${ROOTPATH}/sites"}"
STOP_CRON_FLAG="${ROOTPATH}/var/tmp/suspend_drupal_cron_flag"
COMPOSER_SET=""

# System User
USER="${USER:-$(whoami)}"
GROUP="${GROUP:-$(groups|awk '{print $0}')}"

# Locale to set
LOCALE="fr"

# drush install related
INSTALL_MARKER="${FORCE_INSTALL_MARKER:-/a/non/existing/file}"
FORCE_INSTALL_MARKER="${FORCE_INSTALL_MARKER:-/a/non/existing/file}"
FORCE_INSTALL="${FORCE_INSTALL:-}"

# name of the base profile to use
# override it in local_conf.sh !
PROFILE_NAME="drupal"

# CODE SOURCE SYNC
SSH_PATH="${HOME}/.ssh/id_dsa"
RSYNC="$(which rsync)"
#unset -v TARGETS
#declare -A TARGETS
#TARGETS["root@localhost"]="/"

# drush preconfigured wrapper
LOCALCOMPOSER="${BINPATH}/composer.phar"
COMPOSER_URL="https://getcomposer.org/composer.phar"

THE_DRUSH_WRAPPER="${BINPATH}/drush"
DRUSH="${BINPATH}/drush"
# drush bare script abs path
DRUSH_CMD="${DRUSH_CMD:-}"
# drush vare script search path if not found
DRUSH_PRETENDANTS="${DRUSH_PRETENDANTS:-"${ROOTPATH}/vendor/drush/drush/drush ${ROOTPATH}/lib/vendor/drush/drush/drush ${ROOTPATH}/sbin/vendor/drush/drush/drush $(which drush) /usr/local/bin/drush /usr/bin/drush drush"}"
#DRUSH_EXTRA_ARGS="--include="${COMMAND_DIRS}" --uri="${DRUPAL_URI}""
DRUSH_CALL=""


has_command() {
    ret=1
    if which which >/dev/null 2>/dev/null;then
      if which "${@}" >/dev/null 2>/dev/null;then
        ret=0
      fi
    else
      if command -v "${@}" >/dev/null 2>/dev/null;then
        ret=0
      else
        if hash -r "${@}" >/dev/null 2>/dev/null;then
            ret=0
        fi
      fi
    fi
    return ${ret}
}

get_command() {
    local p=
    local cmd="${@}"
    if which which >/dev/null 2>/dev/null;then
        p=$(which "${cmd}" 2>/dev/null)
    fi
    if [ "x${p}" = "x" ];then
        p=$(export IFS=:;
            echo "${PATH-}" | while read -ra pathea;do
                for pathe in "${pathea[@]}";do
                    pc="${pathe}/${cmd}";
                    if [ -x "${pc}" ]; then
                        p="${pc}"
                    fi
                done
                if [ "x${p}" != "x" ]; then echo "${p}";break;fi
            done )
    fi
    if [ "x${p}" != "x" ];then
        echo "${p}"
    fi
}

reset_colors() {
    if [[ -n ${NO_COLOR} ]]; then
        BLUE=""
        YELLOW=""
        RED=""
        CYAN=""
    fi
}

log_() {
    reset_colors
    logger_color=${1:-${RED}}
    msg_color=${2:-${YELLOW}}
    shift;shift;
    logger_slug="${logger_color}[${LOGGER_NAME}]${NORMAL} "
    if [[ -n ${NO_LOGGER_SLUG} ]];then
        logger_slug=""
    fi
    printf "${logger_slug}${msg_color}$(echo "${@}")${NORMAL}\n" >&2;
    printf "" >&2;  # flush
}

log() {
    log_ "${RED}" "${CYAN}" "${@}"
}

warn() {
    log_ "${RED}" "${CYAN}" "${YELLOW}[WARN] ${@}${NORMAL}"
}

may_die() {
    reset_colors
    thetest=${1:-1}
    rc=${2:-1}
    shift
    shift
    if [ "x${thetest}" != "x0" ]; then
        if [[ -z "${NO_HEADER-}" ]]; then
            NO_LOGGER_SLUG=y log_ "" "${CYAN}" "Problem detected:"
        fi
        NO_LOGGER_SLUG=y log_ "${RED}" "${RED}" "$@"
        exit $rc
    fi
}

die() {
    may_die 1 1 "${@}"
}

die_in_error_() {
    ret=${1}
    shift
    msg="${@:-"$ERROR_MSG"}"
    may_die "${ret}" "${ret}" "${msg}"
}

die_in_error() {
    die_in_error_ "${?}" "${@}"
}

debug() {
    if [[ -n "${DEBUG// }" ]];then
        log_ "${YELLOW}" "${YELLOW}" "${@}"
    fi
}

vvv() {
    debug "${@}"
    "${@}"
}

vv() {
    log "${@}"
    "${@}"
}


sync_src() {
    cd "${ROOTPATH}"
    echo "${YELLOW}+ Running ${ROOTPATH}/sbin/sync-sources-and-settings.sh${NORMAL}"
    # store choice for underlying script interaction
    export USER_CHOICE
    "${BINPATH}/sync-sources-and-settings.sh"
}

settings_folder_write_fix() {
    cd "${ROOTPATH}"
    echo "${YELLOW}+ Check Write rights in ${ROOTPATH}/sites/default${NORMAL}"
    chmod u+w "${ROOTPATH}/sites/default"
    chown ${USER}:${GROUP} "${ROOTPATH}/sites/default"
}

test_drush_status()  {
    call_drush status --format=yaml|grep -q "bootstrap: Successful"
    return $?
}

git_checkout() {
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

filter_drush() {
    # Prevent fork bombs
    if [ "x${1}" != "x${THIS_SCRIPT}" ];then
        if [ "x${1}" != "x${THE_DRUSH_WRAPPER}" ];then
            echo "${1}"
        fi
    fi
}

install_drush() {
    cd "${BINPATH}"
    call_composer require "${DRUSH_SPEC}"
}

set_drush() {
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
            die "no drush found"
        fi
        DRUSH_CALL="${DRUSH_CMD} --root="${WWW_DIR}" ${DRUSH_EXTRA_ARGS}"
    fi
}

bad_exit() {
        echo ;
        echo "${RED} ERROR: ${1}" >&2;
        echo "${NORMAL}" >&2;
        exit ${END_FAIL};
}

check_conf_arg() {
    CONFARG=${1}
    if [ "x${!CONFARG}" == "x" ]; then
        bad_exit "${CONFARG} is not defined in configuration file"
    fi
}

ask() {
    local ask=${ASK:-}
    if [[ -n $NONINTERACTIVE ]];then
        ask=${ask:-yauto}
    fi
    UNDONE=1
    NO_AVOID=${2}
    echo "${NORMAL}"
    while :
    do
        if [ "x${ask}" = "xyauto" ]; then
          echo " * ${1} [o/n]: ${GREEN}y (auto)${NORMAL}"
          USER_CHOICE=ok
          break
        fi
        read -r -p " * ${1} [o/n]: " USER_CHOICE
        if [ "x${USER_CHOICE}" == "xn" ]; then
            if [ "x${NO_AVOID}" == "xNO_AVOID_MESSAGE" ]; then
                echo "${GREEN}  --> no${NORMAL}"
                USER_CHOICE=abort
            else
                echo "${BLUE}  --> ok, step avoided.${NORMAL}"
                USER_CHOICE=abort
            fi
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

set_composer() {
    composer_pretendants="${COMPOSER_PRETENDANTS} /usr/local/bin/composer"
    composer_pretendants="${composer_pretendants} /usr/bin/composer"
    composer_pretendants="${composer_pretendants} $(get_command composer)"
    if [ "x${COMPOSER_SET}" = "x" ];then
        composer=""
        for c in ${composer_pretendants};do
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

call_composer() {
    set_composer
    "${COMPOSER_SET}" "${@}"
}

call_drush() {
    local pre=""
    if [ "x${DB_TYPE}" = "xpgsql" ] && [ "x${DB_PASS}" != "x" ];then
        export PGPASSWORD="$DB_PASS"
    fi
    if [ "x$1" == "xstrace" ];then
        pre="strace -f"
        shift
    fi
    set_drush
    # Always cd in drupal www dir before running drush !
    cwd="$(pwd)"
    cd "${WWW_DIR}"
    ${pre} ${DRUSH_CALL} "${@}"
    ret=$?
    cd "${cwd}"
    return $ret
}

verbose_call_drush() {
    echo "${YELLOW}+ drush ${@}${NORMAL}"
    call_drush "${@}"
}
drupal_profile() {
    echo "${DRUPAL_PROFILE:-"${WWW_DIR}/profiles/${PROFILE_NAME}"}"
}

drupal_profile_config() {
    echo "${DRUPAL_PROFILE_CONFIG:-"$(drupal_profile)/config"}"
}

drupal_profile_config_sync() {
    echo "${DRUPAL_PROFILE_CONFIG_SYNC:-"$(drupal_profile_config)/sync"}"
}

suspend_cron() {
    echo "${YELLOW}+ touch ${STOP_CRON_FLAG}${NORMAL}"
    touch "${STOP_CRON_FLAG}"
}

unsuspend_cron() {
    echo "${YELLOW}+ rm -f  ${STOP_CRON_FLAG}${NORMAL}"
    rm -f "${STOP_CRON_FLAG}"
}

maintenance_mode() {
    echo "${YELLOW}+ drush vset maintenance_mode 1${NORMAL}"
    ${BINPATH}/drush vset maintenance_mode 1
}

undo_maintenance_mode() {
    echo "${YELLOW}+ drush vset maintenance_mode 0${NORMAL}"
    ${BINPATH}/drush vset maintenance_mode 0
}

activate_maintenance() {
    maintenance_mode
    suspend_cron
}

deactivate_maintenance() {
    undo_maintenance_mode
    unsuspend_cron
}

drush_updb() {
    verbose_call_drush -y updb
}

drush_fra() {
    verbose_call_drush -y fr-all
}

drush_cc_all() {
    verbose_call_drush -y cc all
}

drush_cim() {
    verbose_call_drush -y cim
}

drush_cr() {
    verbose_call_drush -y cr
}

do_sync() {
    dest="$(basename ${1})"
    fdest="${1}"
    ftarget="${2}"
    shift
    shift
    echo "${YELLOW}== now Rsync ${dest}...${NORMAL}"
    "${RSYNC}" -e 'ssh -i "${SSH_PATH}"' -av --stats --del --ignore-errors --force ${@} "${fdest}" "${ftarget}"
}

die() {
    echo "$@"
    exit 1
}

has_ignited_db() {
    case $DB_TYPE in
        postgres*|pgsql)
            NB_TABLES=$( call_drush sqlq --extra="-t" "SELECT COUNT(*) FROM information_schema.tables WHERE table_catalog ='${DB_NAME}' AND table_schema NOT IN ('pg_catalog', 'information_schema');" 2>/dev/null; );;
        *)
            NB_TABLES=$(call_drush sqlq --extra="-N" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}';" 2>/dev/null);;
    esac
    test "${NB_TABLES}" -gt "10"
}

rsync_www() {
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

check_default_symlink() {
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

# LOAD USER DEFINED VARS and OVERRIDEN FUNCTIONS !!!
ENV_SET=""
SETTINGS="${BINPATH}/local_conf.sh"
# override any environment settings via local shell files
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
# vim:set et sts=4 ts=4 tw=0:
