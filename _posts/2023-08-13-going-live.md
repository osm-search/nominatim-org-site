---
layout: post
title: "New frontend available on nominatim.openstreetmap.org"
author: Sarah Hoffmann (lonvia)
---

The rewritten search frontend of Nominatim has just been rolled out on
OSM's main instance [https://nominatim.openstreetmap.org](https://nominatim.openstreetmap.org).
Give it a try.

After half a year of development, the completely rewritten frontend for
Nominatim is now ready for production. While it may still look the same on
the outside, a lot has changed with the implementation, especially for
forward search.  It closes as many as
[10 outstanding issues](https://github.com/osm-search/Nominatim/issues?q=is%3Aissue+milestone%3A%22Python+API%22+is%3Aclosed),
some as old as 5 years. If you want to now more about what has changed
in the frontend, read the previous posts about
[frontend renovations]({% link _posts/2022-12-08-frontend-renovation.md %})
and [improving search]({% link _posts/2023-04-27-improving-search.md %}).

Most of the API has been ported as is to the new frontend. However, the
new implementation is slightly more strict and some long deprecated features
are now gone. Here are the most important changes:

* HTTP requests must now use the GET method and make sure the URL is properly
  percentage-encoded. POST requests or queries in raw UTF-8 are no longer
  accepted.
* The `osm_type` and `osm_id` parameters for reverse have been removed.
  Use the [lookup](https://nominatim.org/release-docs/develop/api/Lookup/)
  endpoint instead.
* URLs with additional slashes (`https://nominatim.openstreetmap.org/reverse/?lat=5.45&lon=-34,5`
  or `https://nominatim.openstreetmap.org/search/MyPlace?format=json`) are no
  longer accepted. Remove the additional slashes and use the `q` parameter
  for searches.
* Search along a route no longer works.
* Mixing structured and unstructured search now raises an error.
  (See [this comment](https://github.com/osm-search/Nominatim/issues/3136#issuecomment-1669668081)
  for context.)

Please give the new frontend a try. Geocoding isn't an exact science. It will
take a while before the new algorithm is tuned to give the best possible
results. Your input can be helpful for the process. If you find that some
searches work worse than before, don't hesitate to open an issue in the
[Nominatim issue tracker](https://github.com/osm-search/Nominatim/issues).


_Many thanks to [NGI Zero](https://nlnet.nl/entrust/) who are funding this
work on improving Nominatim._
