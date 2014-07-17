{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}

{{cfg.name}}-cron:
  cmd.run:
    - name: {{data.cron_cmd}}
    - cwd: {{cfg.project_root}}/www
    - user: {{cfg.user}}
    - use_vt: true
