{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
include:
  - makina-projects.{{cfg.name}}.task_maintainance
  - makina-projects.{{cfg.name}}.task_remove_maintainance
{{cfg.name}}-upgrade:
  cmd.run:
    - name: ../sbin/upgrade.sh
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
    - require:
      - mc_proxy: {{cfg.name}}-drush-activated-maintenance
    - require_in:
      - mc_proxy: {{cfg.name}}-drush-remove-maintenance
