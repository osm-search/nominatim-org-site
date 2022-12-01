---
layout: tutorial
title: "Running Nominatim and Rendering in a Single Database"
author: Sarah Hoffmann (lonvia)
tags: import flex-output
---

This tutorial shows how to set up a custom import style which creates a
rendering database next to the geocoding database.

Since version 4.2.0 Nominatim allows to use osm2pgsql's
[flex output](https://osm2pgsql.org/doc/manual.html#the-flex-output)
to describe the table layout for the initial import. The Lua-based style
is a lot more flexible than the simple
[json import configuration](https://nominatim.org/release-docs/latest/customize/Import-Styles/)
offered by Nominatim right now. One of the things you can do with it, is to create
additional tables next to the ones needed by Nominatim. This paves the road
to a much requested feature: running geocoding and rendering maps from the
very same database.

This tutorial uses an **experimental** feature of Nominatim. You will need
the latest release to make it work. Please use with care and be aware that
details of the process may change in the future.
{:.warning}

## Choosing the import styles

In order to have a combined database, you need to have a flex style configuration
for all the separate parts. For this tutorial we will use the
`import-extratags.lua` style for the Nominatim database and the
`compatible.lua` style from the flex example of osm2pgsql for the rendering
database. The latter just stands in as an example layout. You will, of course,
need to choose the style that provides the
rendering database for your particular map layout.

Two osm2pgsql flex styles can only be used together when they

* define different table names for their output tables
* have different names for all global Lua variables they use.

As a rule, you should try to avoid using global variables in your Lua style
files as much as possible. Database schemas are a great way to avoid clashes
with table names.

When choosing the style, make sure it is really meant to work with the flex
output. Styles like [osm-carto](https://github.com/gravitystorm/openstreetmap-carto)
still use the pgsql output with a Lua tagtransform script. This cannot be
used with the flex style. Have a look at the experimental
[carto flex](https://github.com/gravitystorm/openstreetmap-carto/pull/4431) branch
if you want to experiment with carto rendering.
{:.warning}

## Preparing the configuration

Nominatim has all the mechanisms for import and updates already built in,
so the easiest way to get to a combined database is to configure it to
set up the rendering tables in addition to its own tables.

First of all, create a [project directory](https://nominatim.org/release-docs/latest/admin/Import/#creating-the-project-directory)
for Nominatim. We use this to collect all the necessary scripts and settings.

``` sh
mkdir project-flex
cd project-flex
```

Now copy all necessary Lua style files into the project directory. This will make
it simpler for Lua to find the styles later. Assuming you have the Nominatim
source code in a directory `$NOMINATIM_SRC`, then run:

``` sh
cp $NOMINATIM_SRC/settings/flex-base.lua .
cp $NOMINATIM_SRC/settings/import-extratags.lua .
cp $NOMINATIM_SRC/osm2pgsql/flex-config/compatible.lua .
```

Next you need a script that combines the two separate style files. Create
a file `flex-combined.lua` in your project directory with the following
content:

``` lua
-- Make sure lua finds out scripts
package.path = '?.lua;' .. package.path

-- load nominatim style
local nominatim = require('import-extratags')

local nominatim_process_node = osm2pgsql.process_node
local nominatim_process_way = osm2pgsql.process_way
local nominatim_process_relation = osm2pgsql.process_relation

--- load mapnik style
local mapnik = require('compatible')

local mapnik_process_node = osm2pgsql.process_node
local mapnik_process_way = osm2pgsql.process_way
local mapnik_process_relation = osm2pgsql.process_relation

-- calling both

function osm2pgsql.process_node(object)
    nominatim_process_node(object)
    mapnik_process_node(object)
end

function osm2pgsql.process_way(object)
    nominatim_process_way(object)
    mapnik_process_way(object)
end

function osm2pgsql.process_relation(object)
    nominatim_process_relation(object)
    mapnik_process_relation(object)
end
```

The script loads each style file in turn and saves their processing functions in
a local variable. Then it overwrites the processing functions with its own
version which simply calls the functions it has previously saved. That's it!

To tell Nominatim about your custom style file, you need to set the appropriate
configuration variable:

```sh
echo NOMINATIM_IMPORT_STYLE=flex-combined.lua >> .env
```

Nominatim has an optimisation where it does not propagate changes in OSM data
to dependent objects. For example, when a node is moved around, then the geometry
of a way that this node is part of usually changes. Such geometry changes are
rarely relevant for geocoding but they are important to update when making
maps. Therefore, disable this optimisation:

```sh
echo NOMINATIM_UPDATE_FORWARD_DEPENDENCIES=yes >> .env
```

If you want to make further changes to the Nominatim configuration like
changing the name of the database or using a flatnode file, have a look at the
[configuration settings](https://nominatim.org/release-docs/latest/customize/Settings/)
and adapt your `.env` file accordingly.

You may also want to [download additional data](https://nominatim.org/release-docs/latest/admin/Import/#downloading-additional-data)
into your project directory at this point.

## Importing and updating

You can now run the import as described in the [Import guide](https://nominatim.org/release-docs/latest/admin/Import/#initial-import-of-the-data):

```sh
nominatim import --osm-file <data file> 2>&1 | tee setup.log
```

Once it is finished, your database will contain the usual tables of a
Nominatim import as well as tables `planet_osm_point`, `planet_osm_line`,
`planet_osm_polygon` and `planet_osm_roads` for rendering.

You can also keep your data up to date by simply following Nominatim's
[update guide](https://nominatim.org/release-docs/latest/admin/Update/).

## Updates with tile expiry

If you want to use the [expiry mechanism](https://osm2pgsql.org/doc/manual.html#expire)
of osm2pgsql to update your tiles, then it is not possible anymore to use
Nominatim's builtin update function. Instead you need to do updates manually
with osm2pgsql and then run the postprocessing. In this section we show
how to do this with
[osm2pgsql-replication](https://osm2pgsql.org/doc/manual.html#keeping-the-database-up-to-date-with-osm2pgsql-replication).
You find the osm2pgsql-replication script bundled with the Nominatim source code
under `osm2pgsql/scripts/osm2pgsql-replication`. Copy the script into your
project directory.


You should already have a combined database imported with Nominatim as shown
above. Next you need to initialise the replication process:

```
./osm2pgsql-replication init -d nominatim
```

If your database is named differently, adapt the name after the '-d' parameter.
Next you need a script that runs all the post-processing steps. Create
a script named `postprocess-update.sh` in your project directory with the
following content:

``` sh
#!/bin/sh

# For Nominatim run the indexing.
nominatim index

# Then run tile expiry.
# This is the example from https://switch2osm.org. Adapt this command to
# whatever you need to do.
render_expired --map=s2o --min-zoom=13 --max-zoom=20 -s /run/renderd/renderd.sock < /var/cache/renderd/dirty_tiles.txt
rm /var/cache/renderd/dirty_tiles.txt
```

Make the script executable:

```
chmod 755 postprocess-update.sh
```

Now you can run a batch of updates with a command like this:

```
./osm2pgsql-replication update -d nominatim --post-processing ./postprocess-update.sh --osm2pgsql-cmd /usr/local/lib/nominatim/osm2pgsql -- -s -a -O flex -S flex-combined.lua -e 12 -o /var/cache/renderd/dirty_tiles.txt
```

The `--osm2pgsql-cmd` parameter tells osm2pgsql-replication where to find the
osm2pgsql binary. This should be the binary bundled with Nominatim. If you
have installed Nominatim somewhere other than the default `/usr/local` you
need to adopt the path. The parameters after `--` are the parameters with
which osm2pgsql is called. Choosing the flex output and the style is of course
mandatory. You might want to add other parameters here. For example, if you
have configured a flatnode file, you must add `-F <location of your file>` to
the parameter list.
