---
layout: default
permalink: /
---

{::options parse_block_html="true" /}

<div class="section title-banner">
<h1>Open-source geocoding</h1>
<h3>with OpenStreetMap data</h3>
</div>

<div class="section description">
Nominatim uses OpenStreetMap data to find locations on Earth by name and
address (geocoding). It can also do the reverse, find an address for any
location on the planet.
</div>

<div class="section download-banner">
<div class="two-column">
<div class="column">
*For occasional use*
### ![black pointer](img/black_pointer.svg) Use the API

[Usage policy](https://operations.osmfoundation.org/policies/nominatim/)

[API documentation](release-docs/develop/api/Overview/)
</div>

<div class="column">
*For power users*
### ![black pointer](img/black_pointer.svg) Install your own

The latest release is [{{site.data.releases[0].name}}](https://www.nominatim.org/release/Nominatim-{{site.data.releases[0].name}}.tar.bz2).

[Installation instructions](release-docs/latest/admin/Installation/)

</div>
</div>
</div>

<div class="section features">
## Features

<div class="two-column">

<div class="featurebox">
### Find places by name or adddress (Geocoding)

Nominatim can power the search box on your website, allowing your users
to type free-form queries ("Cafe Paris, New York") in any language.
It also offers a structured query mode
("postcode=12345", "city=London", "type=cafe")
that helps you to automate geocoding of extensive address lists.
</div>


<div class="featurebox">
### Look up addresses for a location (Reverse geocoding)

Given a latitude and longitude anywhere on the planet, Nominatim can find the
nearest address. It can do the same for any OSM object
given its ID.
</div>
</div>

<div class="two-column">

<div class="featurebox">
### Scalable installation

Nominatim scales with your needs. Run a search service for your city
on a laptop or set up a larger server with data of the whole planet.
</div>

<div class="featurebox">
### Configurable setup

You can decide which features of OpenStreetMap are important to you.
Nominatim imports only what you tell it to.
</div>
</div>

<div class="two-column">

<div class="featurebox">
### Always up-to-date with OpenStreetMap

OpenStreetMap data is constantly improved by thousands of editors. Keep
up to date with these changes through minutely updates.
</div>

<div class="featurebox">
### Fast

Nominatim is the geocoding software that powers the
official OSM site [www.openstreetmap.org](https://www.openstreetmap.org/). It servers 30 million queries per
day on a single server.


</div>

</div>
</div>

<div class="section supporters">
## Supporters

We thank the following companies for their support of parts of the
Nominatim development:

[![OpenCage](img/opencage.svg)](https://opencagedata.com/)
[![Graphhopper](img/graphhopper.png)](https://www.graphhopper.com/)
</div>
