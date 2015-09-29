{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set php = salt['mc_php.settings']() %}
include:
  - makina-projects.{{cfg.name}}.includes.maintenance

{{cfg.name}}-drush-set-maintenance-mode:
  cmd.run:
    - name: ../sbin/toggle_maintainance.sh 1
    - cwd: {{cfg.project_root}}/www
    - user: root
    - use_vt: true
    - require:
      - mc_proxy: {{cfg.name}}-drush-activate-maintenance
    - require_in:
      - mc_proxy: {{cfg.name}}-drush-activated-maintenance
