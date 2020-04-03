---
layout: page
permalink: /release-history/
title: Release History
---

The latest release is {{site.data.releases[0].name}}.

{% for rel in site.data.releases %}

### {{rel.name}}

Released: {{rel.date}}

Download: [Nominatim-{{rel.name}}.tar.bz2](https://www.nominatim.org/release/Nominatim-{{rel.name}}.tar.bz2)

[Release Notes](https://github.com/osm-search/Nominatim/releases/tag/v{{rel.name}})
{% if rel.doc != "none" -%}
[Release documentation](/release-docs/{{rel.doc}}/)
{% endif %}


{% endfor %}
