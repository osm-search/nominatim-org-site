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

{% if rel.doc == "wiki" %}
[Installation instructions](http://wiki.openstreetmap.org/wiki/Nominatim/Installation)
{% else %}
[Installation instructions](docs/{{rel.name}}/Installation)
{% endif %}

{% endfor %}
