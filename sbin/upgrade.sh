#!/usr/bin/env bash
. "$(dirname ${0})/base.sh"
standard_upgrade() {
    set -e
    verbose_call_drush -y fra
    verbose_call_drush -y updb
    verbose_call_drush -y cc drush
    verbose_call_drush -y cc all
    set +e
}

run_() {
    echo "${RED}+ Upgrade: ${@}${NORMAL}"
    "${@}"
}

fn_exists() {
    ( LANG=C LC_ALL=C type $1 | grep -q 'function' )
    return ${?}
}

test_prereqs() {
    test_drush_status
    ret=$?
    return $ret
}

if test_prereqs;then
    dnoup=""
    for migfile in $(\
        find "${BINPATH}/upgrade.d/" -mindepth 0 -maxdepth 1\
        -name 'upgrade*.sh' -type f\
        | sort -h \
    );do
        . ${migfile}
        basen="$(basename ${migfile} .sh)"
        test_fun="test_${basen}"
        mig_fun="${basen}"
        if fn_exists "${test_fun}" && fn_exists "${mig_fun}";then
            dnoup="1"
            if "${test_fun}";then
                run_ "${mig_fun}"
            else
                echo "${YELLOW}- ${mig_fun} skipped${NORMAL}"
            fi
        else
            echo "${RED}invalid migration file: ${migfile}, missing functions${NORMAL}"
        fi
    done
    if [ "x${dnoup}" = "x" ];then
        # deactivated for now, only specific upgrade are allowed to be planned
        # automatically
        echo "run_ standard_upgrade"
    fi
else
    die "no drush"
fi
# vim:set et sts=4 ts=4 tw=80:
