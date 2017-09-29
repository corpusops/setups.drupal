#!/usr/bin/env bash
LOG="{{cfg.data_root}}/cron.log"
lock="${0}.lock"
find "${lock}" -type f -mmin +1 -delete 1>/dev/null 2>&1
if [ -e "${lock}" ];then
    echo "Locked ${0}";exit 1
fi
touch "${lock}"
{{data.cron_cmd}}
ret="${?}"
rm -f "${lock}"
if [ "x${ret}" != "x0" ];then
    cat "${LOG}"
fi
exit "${ret}"

#!/usr/bin/env bash
{% set cfg = cops_drupal_vars %}
# this one uses a per fqdn directory on
LOG="{{cfg.data_root}}/var/log/cron/{{ansible_fqdn}}/drupal_cron.log"
# this one is shared wih other servers (when there's a shared disk, tmp is shared)
lock="{{cfg.data_root}}/var/tmp/run_cron.lock"
find "${lock}" -type f -mmin +{{cfg.cron_lock_minutes}} -delete 1>/dev/null 2>&1
if [ -e "${lock}" ];then
    echo "Locked ${0}";exit 1
fi
touch "${lock}"
# Run Drupal/Elysia cron
{{data.cron_cmd}} >${LOG} 2>&1
ret="${?}"

# Here add any symfony console cron, if any
# {{cfg.project_root}}/sbin/console zorglub --cron >${LOG} 2>&1
# ret2="${?}"
# ret1=${ret}
# [ "x$ret1$ret2" == "x00" ]
# ret="${?}"

rm -f "${lock}"
if [ "x${ret}" != "x0" ];then
    cat "${LOG}"
fi
exit "${ret}"
