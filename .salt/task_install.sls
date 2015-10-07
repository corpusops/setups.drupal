{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
include:
  - makina-projects.{{cfg.name}}.task_maintainance
  - makina-projects.{{cfg.name}}.task_remove_maintainance

# dont forget that all script embed a lot of condition for them to really run
# drush make or site-install.
# you can force or postpone the execution via marker files or
# environment variables.
{{cfg.name}}-drush-make:
  cmd.run:
    - name: ../sbin/make.sh && rm -f "{{cfg.data_root}}/force_make"
    - cwd: {{cfg.project_root}}/www
    - user: root
    - use_vt: true
    - require:
      - mc_proxy: {{cfg.name}}-drush-activated-maintenance
    - require_in:
      - mc_proxy: {{cfg.name}}-drush-remove-maintenance
{{cfg.name}}-drush-install:
  cmd.run:
    - name: |
            set -e
            ../sbin/install.sh
            touch "{{cfg.data_root}}/installed"
            rm -f "{{cfg.data_root}}/force_reinstall"
    - cwd: {{cfg.project_root}}/www
    - user: root
    - use_vt: true
    - require:
      - cmd: {{cfg.name}}-drush-make
    - require:
      - mc_proxy: {{cfg.name}}-drush-activated-maintenance
    - require_in:
      - mc_proxy: {{cfg.name}}-drush-remove-maintenance
