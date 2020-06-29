{% from "apache/map.jinja" import apache with context %}

include:
  - apache

{% if grains['os_family'] == "RedHat" %}
apache-vhosts-conf:
  file.managed:
    - name: {{ apache.confdir }}/vhosts.conf
    - contents: |
        IncludeOptional {{ apache.vhostdir }}/*.conf
    - require:
        - pkg: apache
        - file: {{ apache.vhostdir }}
{% endif %}

{% for id, site in salt['pillar.get']('apache:sites', {}).items() %}
{% set documentroot = site.get('DocumentRoot', '{0}/{1}'.format(apache.wwwdir, id)) %}
{%- set managed = site.get('managed', True) %}

{{ id }}:
  file.managed:
    - name: {{ apache.vhostdir }}/{{ id }}{{ apache.confext }}
{%- if managed != False %}
    - source: {{ site.get('template_file', 'salt://apache/vhosts/standard.tmpl') }}
    - template: {{ site.get('template_engine', 'jinja') }}
    - context:
        id: {{ id|json }}
        site: {{ site|json }}
        map: {{ apache|json }}
{%- else %}
    - replace: False
{%- endif %}
    - require:
      - pkg: apache
{%- if grains['os_family'] == "RedHat" %}
      - file: apache-vhosts-conf
{%- endif %}
    - watch_in:
      - module: apache-reload

{% if managed != False and site.get('DocumentRoot') != False %}
{{ id }}-documentroot:
  file.directory:
    - unless: test -d {{ documentroot }}
    - name: {{ documentroot }}
    - makedirs: True
    - allow_symlink: True
{% endif %}

{% if grains.os_family == 'Debian' %}
{% if site.get('enabled', True) %}
a2ensite {{ id }}{{ apache.confext }}:
  cmd.run:
    - unless: test -f /etc/apache2/sites-enabled/{{ id }}{{ apache.confext }}
    - require:
      - file: /etc/apache2/sites-available/{{ id }}{{ apache.confext }}
    - watch_in:
      - module: apache-reload
{% else %}
a2dissite {{ id }}{{ apache.confext }}:
  cmd.run:
    - onlyif: test -f /etc/apache2/sites-enabled/{{ id }}{{ apache.confext }}
    - require:
      - file: /etc/apache2/sites-available/{{ id }}{{ apache.confext }}
    - watch_in:
      - module: apache-reload
{% endif %}
{% endif %}

{% endfor %}
