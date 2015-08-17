{% set cfg = opts['ms_project'] %}
{# export macro to callees #}
{% set cfg = salt['mc_usergroup.settings']() %}
{% set locs = salt['mc_locations.settings']() %}
{% set cfg = opts['ms_project'] %}
{% set lsettings = cfg.data.local_settings %}
{{cfg.name}}-restricted-perms:
  file.managed:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - mode: 750
    - user: {% if not cfg.no_user%}{{cfg.user}}{% else -%}root{% endif %}
    - group: {{cfg.group}}
    - contents: |
            #!/usr/bin/env bash
            gpasswd -a www-data "{{cfg.group}}"
            for i in \
              "{{cfg.project_dir}}/global-reset-perms.sh" \
              "{{cfg.project_root}}/.." \
              "{{cfg.project_root}}/../.."\
              ;do
              setfacl -k "${i}";setfacl -b "${i}";
            done
            for i in \
                "{{cfg.project_root}}" \
                "{{cfg.data_root}}" \
                "{{cfg.pillar_root}}" \
              ;do \
              setfacl -R -k "${i}";setfacl -R -b "${i}";
            done
            if [ -e "{{cfg.pillar_root}}" ];then
              "{{locs.resetperms}}" -q --no-acls \
                --dmode '0771' --fmode '0770'\
                --user root --group root \
                --paths "{{cfg.pillar_root}}";
            fi
            if [ -e "{{cfg.project_root}}" ];then
             {{locs.resetperms}} -q --no-recursive --no-acls\
               -u root -g root --dmode 0751 --fmode 755 \
               --paths "{{cfg.project_dir}}/global-reset-perms.sh" \
               --paths "{{cfg.project_root}}/.." \
               --paths "{{cfg.project_root}}/../..";
             chmod g-s "{{cfg.project_root}}" "{{cfg.data_root}}"
             chmod 771 "{{cfg.project_root}}" "{{cfg.data_root}}"
             chown "{{cfg.user}}:{{cfg.group}}" "{{cfg.project_root}}" "{{cfg.data_root}}"
             find "{{cfg.data_root}}/var" "{{cfg.data_root}}/var/run" \
               -maxdepth 1 -mindepth 1 | \
               egrep '((/(sites|run|private|tmp|log))|sock)'|while read f;do
                {{locs.resetperms}} -q --no-acls \
                  --fmode 771 --dmode 2771 \
                  -u {{cfg.user}} -g {{cfg.group}} \
                  --paths "$f";
             done
             find "{{cfg.project_root}}" "{{cfg.data_root}}" -name .git|while read f;do
              {{locs.resetperms}} -q --no-acls\
               --fmode 770 --dmode 2771 --paths "${f}"\
               -u {{cfg.user}} -g {{cfg.group}};
             done
             find -H \
               "{{cfg.project_root}}/sites" \
               --paths "{{cfg.data_root}}/var/sites"\
               "{{cfg.project_root}}/www" \
               "{{cfg.data_root}}/www" \
               -type d|while read f;do
               chmod g-s,o+x "${f}"
               chown "{{cfg.user}}:{{cfg.group}}" "${f}"
               chmod g+s,o+x "${f}"
             done
             find "{{cfg.data_root}}/var/sites" -maxdepth 1 -mindepth 1|\
              egrep "/(sites|run|private|tmp|log)"|while read f;do
                {{locs.resetperms}} -q --no-acls\
                  --fmode 440 --dmode 551 \
                  -u {{cfg.user}} -g {{cfg.group}}\
                  --paths "$f";
             done
             {{locs.resetperms}} -q --no-acls\
               --fmode 770 --dmode 771 \
               -u {{cfg.user}} -g {{cfg.group}}\
               --paths "{{cfg.data_root}}/var/sites"\
               --excludes=".*files.+";
             {{locs.resetperms}} -q --no-recursive --no-acls\
               --dmode 2771 -u root -g root \
               --paths "{{cfg.data_root}}"\
               --paths "{{cfg.data_root}}/var";
             {{locs.resetperms}} -q --no-recursive --no-acls\
               --fmode  664 -u {{cfg.user}} -g {{cfg.group}}\
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
                 --fmode 770 --dmode 2771\
                 -u {{cfg.user}} -g {{cfg.group}}\
                 --paths "${x}";
             done
            fi
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

