{% set cfg = opts.ms_project %}
{% for i in ['composer', 'drush'] %}
"{{cfg.name}}-{{i}}-install":
  cmd.run:
    {# the wrapper will download the script if neccesary #}
    - name: "{{cfg.project_root}}/sbin/{{i}} --version"
    - user: {{cfg.user}}
    - use_vt: true
{% endfor %}
