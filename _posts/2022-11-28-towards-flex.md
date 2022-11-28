---
layout: post
title: "Feature preview: osm2pgsql flex output"
author: Sarah Hoffmann (lonvia)
---

The latest release of Nominatim has received experimental support for the
[osm2pgsql flex output](https://osm2pgsql.org/doc/manual.html#the-flex-output).
This gives not only more flexibility in the future how OpenStreetMap data is
read and interpreted but also unlocks an often requested feature: running
geocoding and tile rendering from the same database.

Nominatim uses [osm2pgsql](https://osm2pgsql.org) to read OpenStreetMap data
files and load them into the database. osm2pgsql takes care of parsing the
data, creating the geometries for the objects and handling updates of data.
However, osm2pgsql was written to produce a database that is suitable for
rendering maps. For geocoding a different layout is needed. And so osm2pgsql
has this special 'gazetteer output' that produces the place table that
Nominatim uses. The problem with that apporach was always that a different
and supposedly independent software had business logic that depended on how
Nominatim works. Because of that tight coupling, Nominatim has always shipped
its own version of osm2pgsql instead of making use of whatever your OS
might install.

osm2pgsql has a new and more flexible output module since version 1.3.0 -- the
'flex output'. It allows to configure via Lua scripts any database layout
the user may want. And that includes the layout currently used by Nominatim.

With the latest release Nominatim now has experimental support for using
osm2pgsql's flex output. When the `NOMINATIM_IMPORT_STYLE` points to a
.lua file, then Nominatim switches internally to using the flex output.
The release ships with a port of the _extratags_ style. You find it in
`settings/import-extratags.lua`. This script produces a place table with 
the same content as the `extratags` import style.
The implementation is still in an experimental stage.
We are still working on it to make it more efficient and more user-friendly
to adapt to specific needs. So be aware that the code might change in future
releases.

### Running geocoding and rendering together

Rendering maps from OSM data, for example as set up on
[switch2osm.org](https://switch2osm.org/serving-tiles/), also uses an
osm2pgsql database. People have often asked, why they cannot have geocoding
and tile rendering in the same database. The good news: with the new flex output
you can do exactly that. There is now a new tutorial in the Cookbook section
that explains how to
[run Nominatim together with another flex style]({% link _tutorials/running-nomintim-and-rendering-together.md %}).

### The Small Print

The support for flex output is still highly experimental at the moment.
Please play around with it and give feedback but be aware of the following
restrictions:

* There is only a port of the _extratags_ import style at the moment.
  There is no documentation yet and the implementation
  is likely going to change in the future.
* osm2pgsql creates a geometry index on the `place` table which Nominatim
  does not need or use. You can savely drop the index. Future versions of
  osm2pgsql will allow to disable the index creation.
* Switching an existing database to flex output is currently not recommended.
  There will be backwards-compatible style scripts later but right now
  migration remains largely untested.

### Acknowledgements

A big thank you to [Geofabrik](https://geofabrik.de) who have generously
supported the work on the flex output.
