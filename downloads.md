---
layout: page
permalink: /downloads/
---

## Download Nominatim

You can download the latest development version from
[github](https://github.com/osm-search/Nominatim).

The latest release is [{{site.data.releases[0].name}}](http://www.nominatim.org/release/Nominatim-{{site.data.releases[0].name}}.tar.bz2).

For older releases, see the [release history](/release-history).


## Additional Files

The following is a list of additional data files useful for Nominatim
installations:

 * [country_grid.sql.gz](/data/country_grid.sql.gz) (mandatory from 3.0.0, included in release tar balls)

    Base geometries for all countries.

 * [gb_postcodes.csv.gz](/data/gb_postcodes.csv.gz)
 * [gb_postcodes_with_ni.csv.gz](/data/gb_postcodes_with_ni.csv.gz)

    Additional postcode data for Great Britain (without and with Northern Ireland).

 * [us_postcodes.csv.gz](/data/us_postcodes.csv.gz)

    Additional postcode data for the United States.

 * [wikimedia-importance.sql.gz](/data/wikimedia-importance.sql.gz)

    Data for result ranking based on Wikipedia/Wikidata.

 * [tiger-nominatim-preprocessed-latest.csv.tar.gz](/data/tiger-nominatim-preprocessed-latest.csv.tar.gz)

   TIGER housenumber data (latest version).
