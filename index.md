---
layout: page
permalink: /
---

**Nominatim** (from the Latin, *by name*) is a tool to search OSM data by name and address and to generate synthetic addresses of OSM points (reverse geocoding).

### Download

You can download the latest development version from
[github](https://github.com/openstreetmap/Nominatim).

The latest release is [{{site.data.releases[0].name}}](http://www.nominatim.org/release/Nominatim-{{site.data.releases[0].name}}.tar.bz2).

For older releases, see the [release history](release-history).

### Documentation

 * [Usage](https://wiki.openstreetmap.org/wiki/Nominatim) gives a short overview
   over the API.
 * [FAQ](faq) answers commonly asked questions by users of the API.
 * [Installation](release-docs/latest/Installation) contains instructions for
   installing your own Nominatim database using the latest
   release. Installation instructions for the [development version](https://github.com/openstreetmap/Nominatim/blob/master/docs/Installation.md) can be found
   on github. For older releases, see the [release history](release-history).

### Additional Files

The following is a list of additional data files useful for Nominatim
installations:

 * [country_grid.sql.gz](data/country_grid.sql.gz) (mandatory from 3.0.0)

    Base geometries for all countries.

 * [gb_postcode_data.sql.gz](data/gb_postcode_data.sql.gz)

    Additional postcode data for Great Britain.

 * [wikipedia_article.sql.bin](data/wikipedia_article.sql.bin)
 * [wikipedia_redirect.sql.bin](data/wikipedia_redirect.sql.bin)

    Data for result ranking based on Wikipedia.
