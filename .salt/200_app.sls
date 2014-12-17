{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set php = salt['mc_php.settings']() %}

{{cfg.name}}-drush-set-maintenance-mode:
  cmd.run:
    - name: ../bin/drush vset maintenance_mode 1
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - onlyif: |
              if [ ! -e "{{cfg.data_root}}/installed" ];then exit 1;fi
              {{cfg.data_root}}/bin/test_drush_status.sh
              exit ${?}

{{cfg.name}}-drupal-suspend_crons:
  file.touch:
    - name: "{{cfg.data_root}}/suspend_cron"
    - user: {{cfg.user}}
    - onlyif: test -e "{{cfg.data_root}}/installed"
    - require:
      - cmd: {{cfg.name}}-drush-set-maintenance-mode

{{cfg.name}}-drush-make:
  cmd.run:
    - name: ../bin/drush make --no-cache {{data.drush_make}} . && rm -f "{{cfg.data_root}}/force_make"
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - onlyif: |
              if test -e "{{cfg.data_root}}/force_make";then exit 0;fi
              {% if data.force.make %}exit 0{%endif %}
              if [ ! -e "{{data.modules_dir}}" ];then
                exit 0
              fi
              cd "{{data.modules_dir}}"
              ret=1
              for f in {{data.modules_check}};do
                 if [ ! -e "${f}" ];then
                   echo $f
                   ret=0
                 fi
              done
              exit ${ret}
    - require:
      - file: {{cfg.name}}-drupal-suspend_crons

{{cfg.name}}-drupal-settings:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/default.settings.php
    - names:
      - {{cfg.project_root}}/www/sites/default/settings.php
      {% if data.local_settings.base_url != 'default' %}
      - {{cfg.project_root}}/www/sites/{{data.local_settings.base_url}}/settings.php
      {% endif %}
    - template: jinja
    - mode: 660
    - user: "{{cfg.user}}"
    - group: "root"
    - defaults:
        cfg: |
             {{scfg}}
    - require:
      - cmd: {{cfg.name}}-drush-make

{{cfg.name}}-drupal-common-settings:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/default.settings.php
    - names:
      - {{cfg.project_root}}/www/sites/default/common.settings.php
      {% if data.local_settings.base_url != 'default' %}
      - {{cfg.project_root}}/www/sites/{{data.local_settings.base_url}}/common.settings.php
      {% endif %}
    - template: jinja
    - mode: 660
    - user: "{{cfg.user}}"
    - group: "root"
    - defaults:
        cfg: |
             {{scfg}}
    - require:
      - cmd: {{cfg.name}}-drush-make

{{cfg.name}}-drupal-local-settings:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/local.settings.php
    - names:
      - {{cfg.project_root}}/www/sites/default/local.settings.php
      {% if data.local_settings.base_url != 'default' %}
      - {{cfg.project_root}}/www/sites/{{data.local_settings.base_url}}/local.settings.php
      {% endif %}
    - template: jinja
    - mode: 660
    - user: "{{cfg.user}}"
    - group: "root"
    - defaults:
        cfg: |
             {{scfg}}
    - require:
      - cmd: {{cfg.name}}-drush-make

{{cfg.name}}-drush-install:
  cmd.run:
    - unless: |
              if test -e "{{cfg.data_root}}/force_reinstall";then exit 1;fi
              if test -e "{{cfg.data_root}}/installed";then exit 0;fi
              {{cfg.data_root}}/bin/test_hasdb.sh
              exit ${?}
    - name: ../bin/drush site-install -v -y {{data.drupal_profile}} --locale={{data.drupal_locale}} --account-name={{data.local_settings.account_name}} --account-pass={{data.local_settings.site_password}} --account-mail={{data.local_settings.account_email}} --site-mail={{data.local_settings.site_email}} --site-name={{data.local_settings.site_name}} --db-url="{{data.db_url}}" install_configure_form.site_default_country={{data.country}} install_configure_form.date_default_timezone={{data.tz}} install_configure_form.update_status_module={{data.update_status_module}} && touch "{{cfg.data_root}}/installed" && rm -f "{{cfg.data_root}}/force_reinstall"
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - require:
      - file: {{cfg.name}}-drupal-settings
      - file: {{cfg.name}}-drupal-common-settings
      - file: {{cfg.name}}-drupal-local-settings

{{cfg.name}}-drush-fra:
  cmd.run:
    - name: ../bin/drush fra -y
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - onlyif: |
              {% if data.force.feature_revert %}"{{cfg.data_root}}/bin/test_drush_status.sh";
              exit $?;{%endif %}
              exit 1;
    - require:
      - cmd: {{cfg.name}}-drush-install

{{cfg.name}}-drush-updb:
  cmd.run:
    - name: ../bin/drush updb -y
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - onlyif: |
              {% if data.force.update_db %}"{{cfg.data_root}}/bin/test_drush_status.sh";
              exit $?;{%endif %}
              exit 1;
    - require:
      - cmd: {{cfg.name}}-drush-fra

{{cfg.name}}-drush-remove-maintenance-mode:
  cmd.run:
    - name: ../bin/drush vset maintenance_mode 0
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - onlyif: |
              {% if data.force.remove_maintenance %}"{{cfg.data_root}}/bin/test_drush_status.sh";
              exit $?;{%endif %}
              exit 1;
    - require:
      - cmd: {{cfg.name}}-drush-updb

{{cfg.name}}-drush-remove-cron_suspension:
  file.absent:
    - name: "{{cfg.data_root}}/suspend_cron"
    - onlyif: |
              {% if data.force.remove_suspend_cron %}"{{cfg.data_root}}/bin/test_drush_status.sh";
              exit $?;{%endif %}
              exit 1;
    - require:
      - cmd: {{cfg.name}}-drush-remove-maintenance-mode

{{cfg.name}}-drush-cc-drush:
  cmd.run:
    - name: ../bin/drush cc drush
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - onlyif: "{{cfg.data_root}}/bin/test_drush_status.sh"
    - require:
      - file: {{cfg.name}}-drush-remove-cron_suspension

{{cfg.name}}-drush-cc-all:
  cmd.run:
    - name: ../bin/drush cc all
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - onlyif: "{{cfg.data_root}}/bin/test_drush_status.sh"
    - require:
      - cmd: {{cfg.name}}-drush-cc-drush

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
                salt-call --out-file="${LOG}" --retcode-passthrough -lall --local mc_project.run_task {{cfg.name}} task_dcron 1>/dev/null 2>/dev/null
                ret="${?}"
                rm -f "${lock}"
                if [ "x${ret}" != "x0" ];then
                  cat "${LOG}"
                fi
                exit "${ret}"
    - user: {{cfg.user}}
    - use_vt: true
    - require:
      - cmd: {{cfg.name}}-drush-cc-all

{{cfg.name}}-cron:
  file.managed:
    - name: "/etc/cron.d/{{cfg.name}}drupalcron"
    - contents: |
                #!/usr/bin/env bash
                MAILTO="{{data.admins}}"
                {{data.cron_periodicity}} root "{{cfg.data_root}}/bin/drupal_cron.sh"
    - user: {{cfg.user}}
    - makedirs: true
    - use_vt: true
    - require:
      - file: {{cfg.name}}-cron-cmd
