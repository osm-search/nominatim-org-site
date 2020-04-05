---
layout: page
permalink: /downloads/
---

## Download Nominatim

You can download the latest development version from
[github](https://github.com/osm-search/Nominatim).

The latest release is [{{site.data.releases[0].name}}](http://www.nominatim.org/release/Nominatim-{{site.data.releases[0].name}}.tar.bz2).

For older releases, see the [release history](release-history).


## Additional Files

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
