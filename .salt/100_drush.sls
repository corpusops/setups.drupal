{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set php = salt['mc_php.settings']() %}

{{cfg.name}}-drush-install:
  cmd.run:
    - name: composer require "drush/drush:6.*"
    - cwd: {{cfg.project_root}}/lib
    - user: {{cfg.user}}
    - use_vt: true

{{cfg.name}}-drush-wrapper:
  file.managed:
    - source: salt://makina-projects/{{cfg.name}}/files/drush_wrapper
    - name: {{cfg.project_root}}/bin/drush
    - template: jinja
    - mode: "0770"
    - user: "{{cfg.user}}"
    - group: "root"
    - defaults:
        project_lib_root: "{{cfg.project_root}}/lib"
        project_web_root: "{{cfg.project_root}}/www"
        project_domain: "{{data.domain}}"
        php: '{{data.php}}'
    - watch:
      - cmd: {{cfg.name}}-drush-install

