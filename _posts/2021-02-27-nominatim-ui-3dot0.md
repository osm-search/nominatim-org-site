---
layout: post
title: "Nominatim-UI v3.0"
author: Marc Tobias (mtmail)
---

With Nominatim 3.6 we have split off the HTML website into a separate project
[nominatim-ui](https://github.com/osm-search/nominatim-ui/). Going forward the
API will only return JSON, XML, geoJSON data while you can install nominatim-ui
to visualize results and aid debugging. For openstreetmap.org it is installed
on [https://nominatim.openstreetmap.org/ui/](https://nominatim.openstreetmap.org/ui/).

Version 2 was a major rewrite into a more dynamic framework ([Svelte](https://svelte.dev))
which will allow more interactive features.

Version 3 adds theming. A recurring issue with the user interface was that a
lot of help text and links assumed it is installed on openstreetmap.org
servers. Now you can add your own help page and own link to report issues.
That is especially helpful for company internal installations that might
have imported different data, old data or e.g. only one country.

![Screenshot of nominatim-ui](/img/nominatim-ui-3dot0.png)
