{% from "apache/map.jinja" import apache with context %}

{%- set os_family = salt['grains.get']('os_family') -%}
{%- set osmajorrelease = salt['grains.get']('osmajorrelease') -%}

include:
  - apache

{{ apache.configfile }}:
  file.managed:
    - template: jinja
    - source:
      - salt://apache/files/{{ os_family }}/{{ osmajorrelease }}/apache-{{ apache.version }}.config.jinja
      - salt://apache/files/{{ os_family }}/apache-{{ apache.version }}.config.jinja
    - require:
      - pkg: apache
    - watch_in:
      - service: apache
    - context:
      apache: {{ apache }}

{{ apache.vhostdir }}:
  file.directory:
    - require:
      - pkg: apache
    - watch_in:
      - service: apache

{% if grains['os_family']=="Debian" %}
/etc/apache2/envvars:
  file.managed:
    - template: jinja
    - source:
      - salt://apache/files/{{ os_family }}/{{ osmajorrelease }}/envvars-{{ apache.version }}.jinja
      - salt://apache/files/{{ os_family }}/envvars-{{ apache.version }}.jinja
    - require:
      - pkg: apache
    - watch_in:
      - service: apache

{{ apache.portsfile }}:
  file.managed:
    - template: jinja
    - source:
      - salt://apache/files/{{ os_family }}/ports-{{ apache.version }}.conf.jinja
    - require:
      - pkg: apache
    - watch_in:
      - service: apache
    - context:
      apache: {{ apache }}

{% endif %}

{% if grains['os_family']=="RedHat" %}
/etc/httpd/conf.d/welcome.conf:
  file.absent:
    - require:
      - pkg: apache
    - watch_in:
      - service: apache
{% endif %}

{% if grains['os_family']=="Suse" %}
/etc/apache2/sysconfig.d/global.conf:
  file.managed:
    - template: jinja
    - source:
      - salt://apache/files/{{ os_family }}/global.config.jinja
    - require:
      - pkg: apache
    - watch_in:
      - service: apache
    - context:
      apache: {{ apache }}
{% endif %}
