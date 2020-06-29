{% from "apache/map.jinja" import apache with context %}

include:
  - apache

mod-php:
  pkg.installed:
    - name: {{ apache.mod_php_pkg }}
    - order: 180
    - require:
      - pkg: apache

{%- if grains['os_family']=="Debian" %}
mod-php-enable:
  cmd.run:
    - name: a2enmod {{ apache.mod_php }}
    - unless: ls /etc/apache2/mods-enabled/{{ apache.mod_php }}.load
    - order: 225
    - require:
      - pkg: mod-php
    - watch_in:
      - module: apache-restart

{% if 'apache' in pillar and 'php-ini' in pillar['apache'] %}
/etc/php/{{ apache.mod_php }}/apache2/php.ini:
  file.managed:
    - source: {{ pillar['apache']['php-ini'] }}
    - order: 225
    - watch_in:
      - module: apache-restart
    - require:
      - pkg: apache
      - pkg: mod-php
{%- endif %}

{%- endif %}
