{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% import "makina-states/services/http/nginx/init.sls" as nginx with context %}
{% import "makina-states/services/php/init.sls" as php with context %}
include:
  - makina-states.services.php.phpfpm_with_nginx

# the fcgi sock is meaned to be at docroot/../var/fcgi/fpm.sock;

# incondentionnaly reboot nginx & fpm upon deployments
echo reboot:
  cmd.run:
    - watch_in:
      - mc_proxy: nginx-pre-restart-hook
      - mc_proxy: nginx-pre-hardrestart-hook
      - mc_proxy: makina-php-pre-restart

# php-user, which is not the project user
{{cfg.name}}-php-user:
  user.present:
    - fullname: {{cfg.name}} php user
    - name: {{cfg.name}}-php
    - shell: /bin/bash
    - gid: www-data
    - remove_groups: True
    - createhome: False
    - empty_password: True
    - watch_in:
      - mc_proxy: makina-php-pre-repo

{% set nginx_params = data.get('nginx', {}) %}
{{nginx.virtualhost(cfg=cfg, **nginx_params) }}

{% set phpfpm_params = data.get('fpm_pool', {}) %}
{% do phpfpm_params.setdefault('pool_name', cfg.name) %}
{{php.fpm_pool(cfg=cfg, **phpfpm_params)}}

{{cfg.name}}-htaccess:
  file.managed:
    - name: {{data.htaccess}}
    - source: ''
    - user: www-data
    - group: www-data
    - mode: 770
    - watch_in:
      - mc_proxy: nginx-pre-conf-hook

{% if data.get('http_users', {}) %}
{% for userrow in data.http_users %}
{% for user, passwd in userrow.items() %}
{{cfg.name}}-{{user}}-htaccess:
  webutil.user_exists:
    - name: {{user}}
    - password: {{passwd}}
    - htpasswd_file: {{data.htaccess}}
    - options: m
    - force: true
    - watch:
      - file: {{cfg.name}}-htaccess
    - watch_in:
      - mc_proxy: nginx-pre-conf-hook
{% endfor %}
{% endfor %}
{% endif %}
