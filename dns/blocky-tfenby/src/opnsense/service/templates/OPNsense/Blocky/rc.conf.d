{% if helpers.exists('OPNsense.Blocky.general.enabled') and OPNsense.Blocky.general.enabled == '1' %}
blocky_enable="YES"
{% else %}
blocky_enable="NO"
{% endif %}
blocky_config="/usr/local/etc/blocky/config.yml"
