---
layout: post
title: "NominatimLite - the database"
author: Sarah Hoffmann (lonvia)
---

Quite a bit has happened in the last years to make Nominatim work well
with with less powerful hardware. One aspect of this is keeping its
database small. But is it small enough that Nominatim fits into a tiny
SQLite database? With the newly introduced SQLAlchemy, we can find out.

[SQLAlchemy](https://www.sqlalchemy.org/) is a very fine piece of software
and a powerful library for anybody who needs to work with SQL databases
in Python. It can be used as a fully-featured ORM or as a simple SQL toolkit.
It's doing quite a good job in integrating SQL queries with
Python code. For the frontend renovation project, it will replace the
many lines of hand-written SQL. The library also functions as an
abstraction layer between the SQL dialects offered by the different SQL
databases. This makes it easy to start playing around with other databases,
in our case SQLite.

### Database-agnostic table schemas

Since about a week, Nominatim's master branch contains
[SQLAlchemy table definitions](https://github.com/osm-search/Nominatim/pull/2963),
for Nominatim's search tables. They were generated semi-automatically with the
help of the [sqlacodegen](https://pypi.org/project/sqlacodegen/) tool from an
existing Nominatim database. Reviewing the code, we find that Nominatim
uses three column types that are PostgreSQL-specific:

* HSTORE - a simple key-value store
* INTARRAY - an array of integers
* JSONB - a more compact binary representation of a json composite type

Luckily all these types can be easily represented by the JSON composite
datatype which is natively supported by SQLite. So, a little bit of
type-aliasing makes the table definition usable for PostgreSQL and SQLite:

```python
if engine_name == 'postgresql':
    Composite: Any = HSTORE
    Json: Any = JSONB
    IntArray: Any = ARRAY(Integer)
elif engine_name == 'sqlite':
    Composite = JSON
    Json = JSON
    IntArray = JSON
```

Nominatim builds on a PostGIS database. So for SQLite we also need its geospatial
variant [SpatialLite](https://www.gaia-gis.it/fossil/libspatialite/index). The
geospatial extension [GeoAlchemy2](https://geoalchemy-2.readthedocs.io)
supports SpatialLite out-of-the-box, so no adaptions were needed to the
table schema with regard to geometries.

### Dumping Nominatim into SpatialLite

Now that we have a schema that works with both database flavours, we can
write a simple script to copy data over row by row:

```python
import sqlalchemy as sa

# Access and schema in source database
indb = sa.create_engine('postgresql:///nominatim')
inmeta = sa.MetaData()
SearchTables(inmeta, 'postgresql')

# Access and schema in destination database
outdb = sa.create_engine('sqlite:///nominatim.sqlite'))
outmeta = sa.MetaData()
SearchTables(outmeta, 'sqlite')

with indb.begin() as inconn, outdb.begin() as outconn:
    # Create the tables in our destination database.
    outmeta.create_all(outconn)

    # Copy all tables row for row.
    for table in inmeta.sorted_tables:
        print(f"Copying '{table}'")
        for row in inconn.execute(table.select()):
            params = row._asdict()
            if 'class' in params:
                params['class_'] = params['class']
            outconn.execute(outmeta.tables[table.key].insert(), params)
```

That's almost it. SpatialLite is an extension to the standard SQLite database
and needs a bit of additional setup before it can be used. GeoAlchemy2 has
[the details](https://geoalchemy-2.readthedocs.io/en/latest/spatialite_tutorial.html#connect-to-the-db).
To make the code above work, add SpatialLite initialisation as follows:

```python
def load_spatialite(dbapi_conn, connection_record):
    dbapi_conn.enable_load_extension(True)
    dbapi_conn.load_extension('/usr/lib/x86_64-linux-gnu/mod_spatialite.so')

sa.event.listen(outdb, 'connect', load_spatialite)
with outdb.begin() as conn:
        conn.execute(sa.select(sa.func.InitSpatialMetaData()))
```

A Nominatim database of Liechtenstein (around 100MB) can be converted in about
30s. That's not bad for such a simplistic dump script.

A quick check with QGIS confirms that the geospatial data shows up as expected:

![World view of Liechtenstein NominatimLite in QGIS](/img/230206-qgis-all.jpg)

What you see here are the fallback geometries for countries. Nominatim
uses them in places, where no other data is available. That is why there
is global coverage for countries. If we zoom in into
Liechtenstein's capital Vaduz, we can see that the other data has been
converted successfully as well including names:

![View of Vaduz of Liechtenstein NominatimLite in QGIS](/img/230206-qgis-vaduz.jpg)

### Ready to use? Not quite.

This was a first experiment with Nominatim and SQLite. It's not the final
database yet. The table schema definitions do not yet contain the proper
definitions for indexes, so SQLAlchemy will have defined a couple of indexes
but not the ones actually needed for searching. In fact, indexes are going
to be one of the major challenges going ahead. The main search index in
Nominatim is implemented as an index over the INTARRAY type. It functions
as an efficient replacement for an
[inverted index](https://en.wikipedia.org/wiki/Inverted_index). For SQLite
we will have to come up with a different solution.

In the coming months we port the forward and backward search functions to
SQLAlchemy and Python. This will be the true reality check for NominatimLite.
