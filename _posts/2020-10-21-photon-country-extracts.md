---
layout: post
title: "Weekly country extracts for Photon"
author: Sarah Hoffmann (lonvia)
---

The [download server for Photon](https://download1.graphhopper.com/public/extracts/by-country-code/)
now offers ready-to-use database dumps for over
200 countries. Setting up your own geocoding server was never easier.

[Photon](https://photon.komoot.io/) is a geocoding server software based on
Nominatim. Photon takes the data from a Nominatim database and loads it into
an ElasticSearch database. As such it combines
the advanced OpenStreetMap data processing mechanism of Nominatim with the
powerful text search capabilities of ElasticSearch. It is multi-lingual
and offers auto-complete functionality.

To make it easier for you to set up your own Photon server, we provide ready-made
database dumps. Creating your own setup is done in three quick steps:

1. Download and extract a dump from [https://download1.graphhopper.com/public/](https://download1.graphhopper.com/public/)
2. Download the [latest release jar of Photon](https://github.com/komoot/photon/releases/latest)
3. Run the server: `java -jar photon-*.jar`

The server is now ready at `http://localhost:2322`. For more information on
building and running photon, visit the [photon github page](https://github.com/komoot/photon).

The database dump of the planet is still pretty large. With 66GB download size, it
needs more than 130GB free disk space to run. For those of you who are tight on
disk space and don't need searching the entire planet, we now offer smaller country-wide
database for over 200 countries. Like the planet dump, they are updated once
a week. You find the new extracts under

    https://download1.graphhopper.com/public/extracts/by-country-code/

There is one directory for each country named by country code.

Many thanks to [Graphhopper](https://www.graphhopper.com/) for making this
service possible.
