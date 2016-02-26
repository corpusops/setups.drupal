{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

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
        cfg: "{{cfg.name}}"

{{cfg.name}}-drupal-common-settings:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/common.settings.php
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
        cfg: "{{cfg.name}}"

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
        cfg: "{{cfg.name}}"

{# This file should not be used anymore, all content is merged in local_conf.sh #}
{{cfg.name}}-remove-sbin-profile_conf.sh:
  file.absent:
    - name: {{cfg.project_root}}/sbin/profile_conf.sh

{{cfg.name}}-sbin-local_conf.sh:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/local_conf.sh
    - name: {{cfg.project_root}}/sbin/local_conf.sh
    - template: jinja
    - mode: 750
    - user: "{{cfg.user}}"
    - group: "root"
    - defaults:
        cfg: "{{cfg.name}}"
    - require:
      - file: {{cfg.name}}-drupal-local-settings
      - file: {{cfg.name}}-remove-sbin-profile_conf.sh
