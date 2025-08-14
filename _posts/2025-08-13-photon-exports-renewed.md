---
layout: post
title: "A New Look for Photon Dumps"
author: Sarah Hoffmann (lonvia)
---

If you have recently visited the
[download site for Photon dump files](https://download1.graphhopper.com/public/)
you may have noticed the new site layout. The site has received a complete overhaul
with new types of dumps, new options for extracts and a nicer presentation.
Read here what has changed.

## Region extracts replace country extracts

The old site used to host one large planet dump and then country extracts in the
`extracts/by-country-code/` directory. The new layout rearranges how you can
find extracts: they are now organised by continent with each continent giving
you a list of available country extracts. For you as a user that means that
**all file locations and names have changed**.

Some of the country extracts were really tiny and didn't make much sense to
have on their own. They have been merged to subregions like the
[Caribbean islands](https://download1.graphhopper.com/public/north-america/caribbean/index.html).
If you need a single country from that subregion, download the JSON dump and
create a Photon database with a country filter. The section on JSON dumps
below explains how this works.

With the new structure, there will now also be extracts for continents on
offer. This will hopefully reduce the hardware requirements on disk space for
those of you that don't need the entire planet but still want to have
multiple countries.

## Photon database dumps

The database dumps are the unzip-and-go database dumps we have always provided.
These are now available for the planet, all continents and some selected
countries. Do remember that the naming schema has changed slightly.
Database dump file names now start with 'photon-db-' and have the suffix
'.tar.bz2'.

Usage of these dumps hasn't changed: download the dump, unpack it and
start Photon.

There are no database dumps anymore for smaller, less popular countries. If
you need a Photon database for those countries, you have to create your own
database from the JSON dumps as described in the next section. This usually
won't take more than an hour.

With version 0.7 being a transitional release between the old ElasticSearch
backend and the new OpenSearch backend, we publish dumps for both versions.
Please make sure that you download the right dump. Photon 0.7.3 and later
will refuse to start if you use the wrong file.

## Photon JSON dumps

The download site now also allows you to download
[JSON dumps](https://github.com/komoot/photon/pull/885) of the Photon data.
These dumps are available for the planet, continents and as country extracts.
JSON dump files start with 'photon-dump-' and have the suffix '.jsonl.zst'. They
use the newer [zstd](https://en.wikipedia.org/wiki/Zstd) for compression.
Make sure you have the appropriate tool installed.

JSON dumps give you the raw data with which you can build your own Photon
database. Apart from being much smaller than the database dumps, they are
also more versatile: they contain a lot more languages[^1], the (almost)
full set of OSM tags as 'extratags' and the full
geometries of the objects. Starting from a JSON dump, you can create
localized databases, databases that allow
[structured search](https://github.com/komoot/photon/blob/master/docs/structured.md)
and databases that [return the full geometry](https://github.com/komoot/photon/pull/823).

You can also combine smaller extracts into one database. Need a geocoding
server for [Benelux](https://en.wikipedia.org/wiki/Benelux)? Download
the extracts for
[Belgium](https://download1.graphhopper.com/public/europe/belgium/index.html),
the [Netherlands](https://download1.graphhopper.com/public/europe/netherlands/index.html)
and [Luxemburg](https://download1.graphhopper.com/public/europe/luxemburg/index.html).
Then create the database by concatenating the downloaded files together:

```
zstd --stdout -d photon-dump-*.jsonl.zst | java -jar photon.jar -nominatim-import -import-file -
```

Or you can go the other way around. Download the JSON dump for
[Europe](https://download1.graphhopper.com/public/europe/index.html)
and then filter for the countries you are interested in during the import:

```
zstd --stdout -d photon-dump-europe-0.7-latest.jsonl.zst | java -jar photon.jar -nominatim-import -import-file - -countries be,nl,lu
```
### Updating a database from JSON dumps

Once you have created your Photon database from a JSON dump, you might want
to update the data from time to time using a more recent JSON dump. You can
do this while the old database is up and running. Just make sure you use
a different cluster name and database location while you do the reimport.

In short, the steps are:

1. Create a directory for the reimport and change into the directory:
   ```
   mkdir /srv/photon-reimport
   cd /srv/photon-reimport
   ```
2. Download the newest extract. Then import it with the same options you used
   for the original import, adding the cluster parameter:
   ```
   zstd --stdout -d photon-dump-*.jsonl.zst | java -jar photon.jar -nominatim-import -import-file - -cluster photon-reimport
   ```
3. Switch out the original database with the newly imported one
   (here we assume the original one is in `/srv/photon`):
   ```
   mv /srv/photon/photon-data /srv/photon/photon-data.old
   mv photon-data /srv/photon/photon-data
   ```
4. Restart your Photon server. The newly imported database will now run inside
   the original cluster 'photon'.


## Which version do I need?

The new download site points you now directly to the right dump to match
the Photon version you are using. We will usually provide extracts for one
or two versions back, so you have a bit of time to switch over your setup.
Keep in mind though that only the dumps for the latest version are
guaranteed to receive weekly updates.

You will also always find a _master_ version of the dumps. These are the dumps
created from the current main development branch. (They used to be found in
the 'experimental' directory before the restructuring.) They are mainly meant
for testing for developers but you are welcome to try out the latest features
and give us feedback.


## Try it out!

The new layout will hopefully make it easier to find and use the appropriate
data to create your own customized geocoding database. The old file locations
will keep working for another couple of months. So you have some time to
adapt your setups. The old files won't receive updates though. If you need
it fresh, switch now.

_Many thanks to [Graphhopper](https://graphhopper.com/) who make the Photon
export service possible by generously sponsoring the server._

[^1]: At the time of writing this blog the full list of supported languages is: en, ru, zh, ja, uk, ar, ko, ca, fr, de, fi, be, pl, es, sr, br, he, sv, el, it, th, ga, oc, kn, ur, ms, nl, my, eu, ka, hu, fa, hi, pt, lt, ro, cs.

