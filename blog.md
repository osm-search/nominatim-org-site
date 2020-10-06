---
layout: blog
permalink: /blog/
---

<div style="text-align: right;"><a href="../feed.xml"><img src="{% link img/feed.svg %}" width="20" height="20" alt="Atom Feed" title="Atom Feed"/></a></div>

# Nominatim Blog

{% for post in site.posts %}
## [{{ post.title }}]({{post.url}})
<small>{{post.date | date: "%b %-d, %Y"}}

{{ post.excerpt }} <a href="{{ post.url }}">Read more ...</a>

<hr>

{% endfor %}
