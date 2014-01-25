{% set cfg = opts['ms_project'] %}
{# export macro to callees #}
{% set locs = salt['mc_locations.settings']() %}
{% set lsettings = cfg.data.local_settings %}
{{cfg.name}}-restricted-perms:
  file.managed:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - mode: 750
    - user: {% if not cfg.no_user%}{{cfg.user}}{% else -%}root{% endif %}
    - group: {{cfg.group}}
    - contents: |
            #!/usr/bin/env bash
            # hack to be sure that nginx is in www-data
            # in most cases
            datagroup="{{cfg.group}}"
            groupadd -r $datagroup 2>/dev/null || /bin/true
            users="nginx www-data"
            for i in $users;do
              gpasswd -a $i $datagroup >/dev/null 2>&1 || /bin/true
            done
            # be sure to remove POSIX acls support
            setfacl -P -R -b -k "{{cfg.project_dir}}"
            "{{locs.resetperms}}" -q --no-acls\
              --user root --group "$datagroup" \
              --dmode '0770' --fmode '0770' \
              --paths "{{cfg.pillar_root}}";
             # web directory loop (user and groups rights)
             find -H \
               "{{cfg.project_root}}/www" \
               \(\
                    \( -type f -and \( -not -perm 0640 \) -and \( -not -path "{{cfg.project_root}}/www/sites/*/files*" \) \)\
                -or \( -type d -and \( -not -perm 2751 \) -and \( -not -path "{{cfg.project_root}}/www/sites/*/files*" \) \)\
               \) \
               2>/dev/null |\
               while read i; do
                   if [ ! -h "${i}" ]; then
                       if [ -d "${i}" ]; then
                           chmod g-s "${i}"
                           chmod 751 "${i}"
                           chmod g+s "${i}"
                       fi
                       if [ -f "${i}" ]; then
                           chmod g-s "$(dirname "${i}")"
                           chmod 0640 "${i}"
                           chmod g+s "$(dirname "${i}")"
                       fi
                   fi
               done
            # general loop (ownership and setgid for directories)
            find -H \
              "{{cfg.project_root}}" \
              "{{cfg.data_root}}" {%if not cfg.remote_less %}"{{cfg.git_root}}"{% endif %} \
              \(\
                \(     -type f -and \( -not -user {{cfg.user}} -or -not -group $datagroup                      \) \)\
                -or \( -type d -and \( -not -user {{cfg.user}} -or -not -group $datagroup -or -not -perm -2000 \) \)\
              \) \
              2>/dev/null |\
              while read i;do
                if [ ! -h "${i}" ];then
                  if [ -d "${i}" ];then
                    chmod g-s "${i}"
                    chown {{cfg.user}}:$datagroup "${i}"
                    chmod g+s "${i}"
                  elif [ -f "${i}" ];then
                    chown {{cfg.user}}:$datagroup "${i}"
                  fi
                fi
             done
             find "{{cfg.data_root}}/var" "{{cfg.data_root}}/var/run" \
               -maxdepth 1 -mindepth 1 2>/dev/null | \
             egrep '((/(sites|run|private|tmp|log))|sock)'|while read f;do
                {{locs.resetperms}} -q --no-acls \
                  --fmode 771 --dmode 2771 \
                  -u {{cfg.user}} -g $datagroup \
                  --paths "$f";
             done
             #{{locs.resetperms}} -q --no-acls\
             #  --fmode 770 --dmode 771 \
             #  -u {{cfg.user}} -g $datagroup\
             #  --paths "{{cfg.data_root}}/var/sites"\
             #  --excludes=".*files.+";
             #{{locs.resetperms}} -q --no-recursive --no-acls\
             #  --dmode 2771 -u root -g root \
             #  --paths "{{cfg.data_root}}"\
             #  --paths "{{cfg.data_root}}/var";
             {{locs.resetperms}} -q --no-recursive --no-acls\
               --fmode  644 -u {{cfg.user}} -g $datagroup\
               --paths "{{cfg.project_root}}"/www/sites/default/settings.php\
               --paths "{{cfg.project_root}}"/www/sites/default/common.settings.php\
               --paths "{{cfg.project_root}}"/www/sites/default/local.settings.php\
               --paths "{{cfg.project_root}}"/www/sites/default/default.settings.php\
               --paths "{{cfg.project_root}}"/www/sites/{{lsettings.base_url}}/settings.php\
               --paths "{{cfg.project_root}}"/www/sites/{{lsettings.base_url}}/common.settings.php\
               --paths "{{cfg.project_root}}"/www/sites/{{lsettings.base_url}}/local.settings.php\
               --paths "{{cfg.project_root}}"/www/sites/{{lsettings.base_url}}/default.settings.php;
             cd '{{cfg.data_root}}/var'
             for x in sites/*/files private;do
               {{locs.resetperms}} -q --no-acls\
                 --fmode 660 --dmode 2771\
                 -u {{cfg.user}} -g $datagroup\
                 --paths "${x}";
             done
            "{{locs.resetperms}}" -q --no-acls --no-recursive\
              --user root --group root --dmode '0555' --fmode '0555' \
              --paths "{{cfg.project_dir}}/global-reset-perms.sh" \
              --paths "{{cfg.project_root}}"/.. \
              --paths "{{cfg.project_root}}"/../..;
  cmd.run:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - cwd: {{cfg.project_root}}
    - user: root
    - watch:
      - file: {{cfg.name}}-restricted-perms

{{cfg.name}}-fixperms:
  file.managed:
    - name: /etc/cron.d/{{cfg.name.replace('.', '_')}}-fixperms
    - user: root
    - mode: 744
    - contents: |
                {{cfg.data.fixperms_cron_periodicity}} root {{cfg.project_dir}}/global-reset-perms.sh

