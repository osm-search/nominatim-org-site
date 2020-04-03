---
layout: page
permalink: /
---

**Nominatim** (from the Latin, *by name*) is a tool to search OSM data by name and address and to generate synthetic addresses of OSM points (reverse geocoding).

### Download

You can download the latest development version from
[github](https://github.com/osm-search/Nominatim).

The latest release is [{{site.data.releases[0].name}}](http://www.nominatim.org/release/Nominatim-{{site.data.releases[0].name}}.tar.bz2).

For older releases, see the [release history](release-history).

### Documentation

See the [documentation of the latest release](release-docs/latest/) for

 * [API documentation](release-docs/latest/api/Overview/)
 * [Installation instructions](release-docs/latest/admin/Installation/)

The documentation for the latest master branch from github (including the version
running on [https://nominatim.openstreetmap.org](https://nominatim.openstreetmap.org)) can be found in the
[development section](/release-docs/develop/).

For older releases, check out the [release history](release-history).


### Additional Files

The following is a list of additional data files useful for Nominatim
installations:

 * [country_grid.sql.gz](data/country_grid.sql.gz) (mandatory from 3.0.0, included in release tar balls)

    Base geometries for all countries.

 * [gb_postcode_data.sql.gz](data/gb_postcode_data.sql.gz)

    Additional postcode data for Great Britain.

 * [us_postcode_data.sql.gz](data/us_postcode_data.sql.gz)

    Additional postcode data for the United States.

 * [wikipedia_article.sql.bin](data/wikipedia_article.sql.bin)
 * [wikipedia_redirect.sql.bin](data/wikipedia_redirect.sql.bin)

    Data for result ranking based on Wikipedia.
