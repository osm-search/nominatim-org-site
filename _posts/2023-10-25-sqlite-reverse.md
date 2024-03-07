---
layout: post
title: "Nominatim lite, part 1: Reverse Geocoding"
author: Sarah Hoffmann (lonvia)
---

The Nominatim Python library, that was added in the last release, makes
it quite a bit easier to work with geocoding on your local machine. Still,
the library needs access to a PostgreSQL database. And setting this up
can be tedious. This is the first of two posts discussing the question:
can a geocoding database be squeezed into a SQLite file?

SQLite has made it really easy to work with smaller SQL databases. A single
file contains all the data and can be easily copied and distributed to run
anywhere from a server to your cell phone. The SpatiaLite extension adds
the spatial capabilities a geocoding database needs.

SQLite can be quite efficient when used read-only, so this is what we target
here: converting an existing Nominatim database into SQLite to be used with
the existing Python frontend. The heavy lifting of preprocessing the data
during import is left to Postgres.

### Converting the database

In [an earlier blog post]({% link _posts/2023-02-06-nominatim-lite.md %}) we
have already seen that it is fairly straightforward to convert the Nominatim
database using SQLAlchemy. A line-by-line copy may not be the fastest method
but it means that we may do some processing or filtering on the way to
optimize the database output.

Creating spatial indexes is a bit more tricky. Spatialite doesn't implement
indexes as first class citizens. Instead the lookup trees are saved in a
special table `SpatialIndex`. The [GeoAlchemy2](https://geoalchemy-2.readthedocs.io)
extension would hide all these details from the SQLAlchemy user.
Unfortunately, we had to get rid of it for
[performance reasons]({% link _posts/2023-07-24-performance-revisited.md %}).
Following GeoAlchemy's example, the convert handles geometry columns now
manually as follows:

* create a placeholder column with type `GEOMETRY`
* convert the column to a geometry column using
  the `RecoverGeometrycolumn()` function
* copy in all data using the `GeometryFromText()` function to import the
  geometry in the correct format
* add a spatial index where necessary using the 
  `CreateSpatialIndex()` function

Nominatim has one index for reverse lookup that is rather special. It is
a partial index over a transformed geometry:

```
CREATE INDEX ON placex
  USING gist (ST_Buffer(geometry, reverse_place_diameter(rank_search)))
  WHERE osm_type = 'N' and rank_address between 4 and 25
```

The index is used to check, if the coordinate that was looked up is still
in the vicinity of a place node, the centre point of a village, city or
similar. What counts as vicinity depends on the type of place. It is smaller
for a hamlet, larger for a town or city.

Spatialite provides support neither for partial spatial indexes nor for indexes
over transformed geometries. The solution here is to resort to a helper table
that holds the transformed geometries. Or to be more precise, it is sufficient
if it holds the bounding box of the transformed geometries because the bounding
box is all that is used by a spatial index.

### Converting the frontend

Once you start trying to run SQL code designed for PostGIS against another
dialect like Spatialite, it becomes clear very quickly that while they may
provide almost the same functionality, there are a lot of tiny but essential
syntactic differences. For example, PostGIS has taken great care to switch
to a consistent naming for all functions using an `ST_` prefix and CamelCase
for the function names. Spatialite still uses the older inconsistent naming
in many places.

While SQLAlchemy is designed to be used with different SQL backends, I doubt
that there is much code out there designed to be used with different backends
at the same time. The library has a concept that allows to provide different
compilations for different dialects. Documentation around this feature
is rather sparse and it takes a few rounds of trial-and-error to get the
implementation right. However, once done right, it does a tremendous job.
There is not a single switch in the implementation of the Reverse API that
needs to distinguish between PostGIS or Spatialite. All dialect-specific
SQL is neatly hidden behind custom SQLAlchemy functions. Here is an example, how
to implement `Greatest` which is called `max` in SQLite:

``` python
import sqlalchemy as sa

class Greatest(sa.sql.functions.GenericFunction):
    """ Function to compute maximum of all its input parameters.
    """
    name = 'greatest'
    inherit_cache = True


@compiles(Greatest, 'sqlite')
def sqlite_greatest(element, compiler, **kw):
    return "max(%s)" % compiler.process(element.clauses, **kw)
```

The new function can then be used like any other function:

``` python
sql = sa.select(sa.func.greatest(1, 3, 5))
```

When running this code against a PostgreSQL connection, SQLAlchemy does the
standard handling for function, which is to render a function with the
given name: `SELECT greatest(1, 3, 5)`. When connected to SQLite, it will
execute the function defined with `@compile` instead. The SQL comes out
as `SELECT max(1, 3, 5)`.
This is pretty straightforward. The tricky part comes when spatial
indexes are involved.

We have already briefly touched on the fact that spatial indexes work
differently in Spatialite. They take the form of a table that needs to be
queried explicitly. As a result, we need to know which queries in the code
are supposed to use a spatial index. This may look like a step backwards
compared to Postgres, which magically uses the right index. However, the
queries in Nominatim are complex enough that we need a tight control over
index use in any case. Being explicit is better for maintainability.

Thus, the relevant spatial functions can now come in two variants:
one with index use and one without. Most functions are used by Nominatim
only in one way or the other, so changes to the code were minimal.


### Testing on Real-World Data

Nominatim in SQLite is not meant for a planet-sized database but rather for
use-cases where a smaller geographic or thematic extract is needed. To
show-case this, we shall test SQLite against two kinds of extract:

* __Germany__ represents one of the best-mapped geographic areas. With
  4.2 million road objects, 19 million address points and 5 million
  additional points of interest, the complete extract makes for a fairly
  large geocoding database.
* __Admin__ is a geocoding database created with Nominatim's
  [admin style](https://nominatim.org/release-docs/latest/admin/Import/#filtering-imported-data).
  It is useful for applications where a search for place names is sufficient,
  for example when tagging photos. It contains 0.5 million boundaries and
  6.5 million place names.

#### Database size

Both database have been created with the import options `--reverse-only` and
`--drop` because we are neither interested in search nor in updates at
this point. The resulting PostgreSQL database was converted with the new
convert command now available with the Nominatim master branch.
The following table shows the size of the PostgreSQL and
SQLite tables:

| Extract | PostgreSQL | SQLite  |
|---------|-----------:|--------:|
| Germany |      29 GB |   18 GB |
| Admin   |      12 GB |   12 GB |

The larger size of the Postgres DB for Germany is mainly the result of
table bloat. After cleaning the table, the database shrinks to 19GB.
Thus, there is no significant difference for the two database types.

Overall the
SQLite files are still a bit larger than is practical. Remember however, that
these files still contain the full wealth of OSM data. Depending on the
use-case, objects like rivers, park benches or dust bins may be dropped.
The SQLite file also contains unmodified geometries. Simplification may reduce
the database size but also lead to incorrect results around the boundaries.

#### Performance

To get a first idea of performance, we tested the two database against
a set of 10.000 random coordinates. Using the new Nominatim library this
can be done with a few lines of code:

``` python
from pathlib import Path
import asyncio
import random
import time
import nominatim.api

async def run_reverse(rounds):
    random.seed(34)
    api = nominatim.api.NominatimAPIAsync(Path('.'))
    for i in range(rounds):
        await api.reverse((random.uniform(5.8, 15.1), random.uniform(47.2, 55.2)),
                          max_rank=random.randint(5, 30))

start = time.time()
asyncio.run(run_reverse(10000))
print(f'Result: {10000/(time.time() - start)} request/s')
```

Here are the results, given in requests per second:

| Extract | PostgreSQL | SQLite  |
|---------|-----------:|--------:|
| Germany |        454 |      23 |
| Admin   |        149 |      21 |

Not surprisingly, Postgres will do a lot better. For one thing, it was designed
for high performance tasks like this. It also has the advantage that it can
make use of additional partial spatial indexes, which cannot be implemented
directly in SQLite as explained above. Still, even with this simple
implementation, the SQLite-based frontend can achieve 20 requests/s in both
cases, which should be sufficient for many use cases.


While there is clearly room for improvement, these experiments have shown that
SQLite is clearly up to the task to serve as a database for a geocoder. Next up
is the search API (or forward geocoding), which comes with another set of
challenges. More on that in the [second part]({% link _posts/2023-12-13-sqlite-search.md %})
of this blog post.

_Many thanks to [NGI Zero](https://nlnet.nl/entrust/) who are funding this
work on improving Nominatim._
