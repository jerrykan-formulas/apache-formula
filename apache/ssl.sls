{% from "apache/map.jinja" import apache with context %}

{%- set ssl = salt['pillar.get']('apache:ssl', {}) -%}

include:
  - apache

{% if ssl -%}
apache-ssl-dir:
  file.directory:
    - name: {{ apache.ssldir }}
    - require:
        - pkg: apache
{%- endif %}

{% for name, values in ssl|dictsort -%}
{%- if 'key' in values %}
apache-ssl-{{ name }}-key:
  file.managed:
    - name: {{ apache.ssldir }}/{{ name }}.key
    - contents: |
        {{ values.key|indent(8) }}
    - user: root
    - group: root
    - mode: 640
    - require:
      - file: apache-ssl-dir
    - watch_in:
      - module: apache-reload
{%- endif %}

{% if 'certificates' in values -%}
apache-ssl-{{ name }}-crt:
  file.managed:
    - name: {{ apache.ssldir }}/{{ name }}.crt
    - contents:
{%- for cert in values.certificates %}
  {%- if 'comment' in cert %}
        - {{ cert.comment }}
  {%- endif %}
        - |
          {{ cert.certificate|indent(10) }}
{%- endfor %}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: apache-ssl-dir
    - watch_in:
      - module: apache-reload
{%- endif %}
{%- endfor %}
