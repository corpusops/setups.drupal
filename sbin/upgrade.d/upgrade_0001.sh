#!/usr/bin/env bash
. "${BINPATH}/upgrade.d/includes/dummy.sh"
test_upgrade_0001() {
    ret=0
    if [ "x$(call_drush sqlq --extra="--skip-column-names" "SELECT 1 FROM system WHERE name = 'foo'")" != "x" ];then
        ret=1
    fi
    return $ret
}

upgrade_0001() {
    set -e
    "${BINPATH}/composer" install
    cd "${WWW_DIR}"
    echo drush_fra
    echo drush_cc_all
}
# vim:set et sts=4 ts=4 tw=80:
