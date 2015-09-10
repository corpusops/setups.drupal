#!/usr/bin/env bash
. "$(dirname ${0})/base.sh"
if [ "x${1}" = "x1" ];then
    activate_maintenance
else
    deactivate_maintenance
fi
# vim:set et sts=4 ts=4 tw=80:
