---
layout: post
title: "Nominatim-UI v3.0"
author: Marc Tobias (mtmail)
---

With Nominatim 3.6 we split off the HTML website into a separate project
[nominatim-ui](https://github.com/osm-search/nominatim-ui/). Going forward the
API will only return JSON, XML, geoJSON data while you can install nominatim-ui
to visualize results and aid debugging. For openstreetmap.org it's installed
on [https://nominatim.openstreetmap.org/ui/]().

Version 2 was a major rewrite into a more dynamic framework ([Svelte](https://svelte.dev))
which will allow more interactive features.

Version 3 adds themeing. A recurring issue with the user interface was that a
lot of help text and links assumed it's installed on openstreetmap.org
servers. Now you can add your own help page and own link to report issues.
That's especially helpful for company internal installations that might
have imported different data, old data or e.g. only one country.

<p><center>
  <a href="/img/nominatim-ui-3dot0.png"><img src="/img/nominatim-ui-3dot0.png" width=400 /></a>
</center></p>
