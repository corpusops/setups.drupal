{% set cfg = opts.ms_project %}
{{cfg.name}}-sbin-composer-json:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/sbincomposer.json
    - name: {{cfg.project_root}}/sbin/composer.json
    - template: jinja
    - mode: 640
    - user: "{{cfg.user}}"
    - group: "{{cfg.group}}"
    - defaults:
      cfg: "{{cfg.name}}"

{# this is not the project composer.lock file -- chich should be versionned --#}
{# this is our sbin composer.lock, we remove it to enforce good versions in #}
{# composer install. In a project composer yu can play with composer update and #}
{# track composer.lock, not here #}
{{cfg.name}}-sbin-composer-remove-lock:
  file.absent:
    - name: "{{cfg.project_root}}/sbin/composer.lock"
{{cfg.name}}-sbin-composer-install:
  cmd.run:
    - name: "{{cfg.project_root}}/sbin/composer install"
    - cwd: {{cfg.project_root}}/sbin
    - user: {{cfg.user}}
    - use_vt: true
    - require:
      - file: {{cfg.name}}-sbin-composer-json
      - file: {{cfg.name}}-sbin-composer-remove-lock

{% for i in ['composer', 'drush'] %}
"{{cfg.name}}-{{i}}-install":
  cmd.run:
    {# the wrapper will download the script if neccesary #}
    - name: "{{cfg.project_root}}/sbin/{{i}} --version"
    - user: {{cfg.user}}
    - use_vt: true
    - require:
      - file: {{cfg.name}}-sbin-composer-json
{% endfor %}
