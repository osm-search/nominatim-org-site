---
layout: default
permalink: /tutorials/
---

# Nominatim Cookbook

This page collects tutorials and howtos around customizing your installation
and using the Nominatim API in unexpected ways.

Do you have used Nominatim in new and unexpected ways and want to share
a tutorial? Please post it in the Nominatim Discussion under
[Show&Tell](https://github.com/osm-search/Nominatim/discussions/categories/show-and-tell).


{% for post in site.tutorials %}
## [{{ post.title }}]({{post.url}})

{{ post.excerpt }}

<small>{% for tag in post.tags %}<span class="post-tag">{{ tag }}</span>{% endfor %}</small>

{% endfor %}
