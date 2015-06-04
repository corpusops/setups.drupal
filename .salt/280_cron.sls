{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

{{cfg.name}}-cron-cmd:
  file.managed:
    - name: "{{cfg.data_root}}/bin/drupal_cron.sh"
    - makedirs: true
    - contents: |
                #!/usr/bin/env bash
                LOG="{{cfg.data_root}}/cron.log"
                lock="${0}.lock"
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
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 750

{{cfg.name}}-cron:
  file.managed:
    - name: "/etc/cron.d/{{cfg.name}}drupalcron"
    - contents: |
                #!/usr/bin/env bash
                MAILTO="{{data.admins}}"
                {{data.cron_periodicity}} root "{{cfg.data_root}}/bin/drupal_cron.sh"
    - user: root
    - group: root
    - makedirs: true
    - require:
      - file: {{cfg.name}}-cron-cmd
