---
layout: page
permalink: /release-history/
title: Release History
---

The latest release is {{site.data.releases[0].name}}.

{% for rel in site.data.releases %}

### {{rel.name}}

Released: {{rel.date}}

Download: [Nominatim-{{rel.name}}.tar.bz2](http://www.nominatim.org/release/Nominatim-{{rel.name}}.tar.bz2)

[Release Notes](https://github.com/openstreetmap/Nominatim/releases/tag/v{{rel.name}})
{% if rel.doc == "wiki" -%}
[Installation instructions](http://wiki.openstreetmap.org/wiki/Nominatim/Installation)
{% else -%}
[Installation instructions](/release-docs/{{rel.name}}/Installation)
{% endif %}


{% endfor %}
