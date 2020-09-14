---
layout: blog
permalink: /blog/
---

# Nominatim Blog

{% for post in site.posts %}
## [{{ post.title }}]({{post.url}})
<small>{{post.date | date: "%b %-d, %Y"}}

{{ post.excerpt }} <a href="{{ post.url }}">Read more ...</a>

<hr>

{% endfor %}
