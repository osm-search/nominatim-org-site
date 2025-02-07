---
layout: tutorial
title: "Running Nominatim and Rendering in a Single Database"
author: Sarah Hoffmann (lonvia)
tags: import flex-output
---

This tutorial shows how to set up a custom import style which creates a
rendering database next to the geocoding database.

The major release 5.0.0 of Nominatim added support for
[osm2pgsql-themepark](https://osm2pgsql.org/themepark/) styles. Themepark
allows to mix and match different osm2pgsql style files for import into
one single database. In this tutorial we use a themepark style to
run a Nominatim search database and a
[osm-carto](https://github.com/gravitystorm/openstreetmap-carto) style
for rendering a map in the same database.

_This tutorial assumes you are running Linux with a stable Debian (Bookworm)
or Ubuntu (24.04). For other Linux flavours or versions, the commands may have
to be slightly adapted._


## Getting the necessary software

To create a combined Nominatim/carto database, three parts are needed: Nominatim,
the rendering style openstreetmap-carto and osm2pgsql themepark.

Nominatim can be installed by following the
[standard installation instructions](https://nominatim.org/release-docs/latest/admin/Installation/).

In short, get the required prerequisites:

```
sudo apt install osm2pgsql postgresql-postgis postgresql-postgis-scripts \
                 pkg-config libicu-dev virtualenv git
```

Create a virtual Python environment and install Nominatim:

```
virtualenv nominatim-venv
./nominatim-venv/bin/pip install nominatim-db
```

Next we need the osm2pgsql-themepark framework. Check this out from github:

```
git clone https://github.com/osm2pgsql-dev/osm2pgsql-themepark
```

The themepark repository already comes with a copy of the osm2pgsql themepark
style for openstreetmap-carto. This is all that is needed to set up the
database import for rendering. So we are already set for the purpose of this
tutorial.

_There are a few more steps to take to go from a rendering database to
serving an actual map. Please refer to the tutorials over at
[Switch2OSM](https://switch2osm.org/serving-tiles/)
to learn about the additional setup you will need to render actual map tiles._

## Setting up the osm2pgsql import style

Nominatim provides a complete infrastructure for importing, updating and
processing OSM data of which the osm2pgsql import is only a small part. If
you want to host additional data next to the Nominatim geocoding database,
it is therefore best to have Nominatim manage the database and only tell
it about the additional style to import.

First create a project directory to host your custom style:

```sh
mkdir project-search-map
```

Now create a file `project-search-map/osm2pgsql-style.lua` with the following
content:

```lua
local themepark = require('themepark')

themepark:add_topic('nominatim/full', {with_extratags = true})
themepark:add_topic('osmcarto/osmcarto')
```

The first `add_topic()` command sets up the equivalent to the 'extratags'
default style of Nominatim. The second command creates the table for the
rendering database.

To tell Nominatim about your custom style file, you need to set the appropriate
configuration variable:

```sh
echo NOMINATIM_IMPORT_STYLE=osm2pgsql-style.lua >> project-search-map/.env
```

If you want to make further changes to the Nominatim configuration like
changing the name of the database or using a flatnode file, have a look at the
[configuration settings](https://nominatim.org/release-docs/latest/customize/Settings/)
and adapt your `.env` file accordingly.

Don't forget to also [download any additional data](https://nominatim.org/release-docs/latest/admin/Import/#downloading-additional-data)
you may need for the import into your project directory at this point.

## Importing and updating

Nominatim is already setup to work with osm2pgsql-themepark. It only needs
to know where to find the themepark lau scripts. Set the LUAPATH accordingly.
Make sure to use the appropriate _absolute_ path:

```sh
export LUAPATH=~/osm2pgsql-themepark/lua/?.lua
```

You can now run the import as described in the [Import guide](https://nominatim.org/release-docs/latest/admin/Import/#initial-import-of-the-data):

```sh
./nominatim-venv/bin/nominatim import --project-dir project-search-map --osm-file <data file> 2>&1 | tee setup.log
```

Once it is finished, your database will contain the usual tables of a
Nominatim import as well as tables `planet_osm_point`, `planet_osm_line`,
`planet_osm_polygon` and `planet_osm_roads` for rendering.

You can also keep your data up to date by simply following Nominatim's
[update guide](https://nominatim.org/release-docs/latest/admin/Update/).

## Updates with tile expiry

If you want to use the [expiry mechanism](https://osm2pgsql.org/doc/manual.html#expire)
of osm2pgsql to update your tiles, then it is not possible to use
Nominatim's builtin update function. Instead you need to do updates manually
with osm2pgsql and then run the postprocessing. In this section we show
how to do this with
[osm2pgsql-replication](https://osm2pgsql.org/doc/manual.html#keeping-the-database-up-to-date-with-osm2pgsql-replication).
This should usually be shipped with your osm2pgsql installation.


You should already have a combined database imported with Nominatim as shown
above. Next you need to initialise the replication process:

```
osm2pgsql-replication init -d nominatim
```

If your database is named differently, adapt the name after the '-d' parameter.
Next you need a script that runs all the post-processing steps. Create
a script named `postprocess-update.sh` in your project directory with the
following content:

``` sh
#!/bin/sh

# For Nominatim run the indexing.
./nominatim-venv/bin/nominatim index

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
osm2pgsql-replication update -d nominatim --post-processing ./postprocess-update.sh --osm2pgsql-cmd /usr/local/lib/nominatim/osm2pgsql -- -s -a -O flex -S osm2pgsql-style.lua -e 12 -o /var/cache/renderd/dirty_tiles.txt
```

The `--osm2pgsql-cmd` parameter tells osm2pgsql-replication where to find the
osm2pgsql binary. This should be the binary bundled with Nominatim. If you
have installed Nominatim somewhere other than the default `/usr/local` you
need to adopt the path. The parameters after `--` are the parameters with
which osm2pgsql is called. Choosing the flex output and the style is of course
mandatory. You might want to add other parameters here. For example, if you
have configured a flatnode file, you must add `-F <location of your file>` to
the parameter list.
