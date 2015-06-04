{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set php = salt['mc_php.settings']() %}

{{cfg.name}}-drush-activate-maintenance:
  mc_proxy.hook:
    - watch_in:
      - mc_proxy: {{cfg.name}}-drush-activated-maintenance

{{cfg.name}}-drush-activated-maintenance:
  mc_proxy.hook:
    - watch_in:
      - mc_proxy: {{cfg.name}}-drush-remove-maintenance

{{cfg.name}}-drush-remove-maintenance:
  mc_proxy.hook:
    - watch_in:
      - mc_proxy: {{cfg.name}}-drush-removed-maintenance

{{cfg.name}}-drush-removed-maintenance:
  mc_proxy.hook: []
