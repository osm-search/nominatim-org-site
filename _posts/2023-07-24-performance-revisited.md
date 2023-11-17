---
layout: post
title: "Python Progress Reports: Tuning SQLAlchemy"
author: Sarah Hoffmann (lonvia)
---

In [this previous post]({% link _posts/2023-04-03-reverse-performance.md %})
we have looked into the performance of the new Python frontend and learned
that it is well worth having a look into optimizations early on. The following
post takes a deep dive into performance tweaks for SQLAlchemy. This means
looking at a rather detailed level at the technical implementation. I
hope that if you plan to play with SQLAlchemy yourself, you might find
one or two good pieces of advice to avoid performance pitfalls in your
own code.

SQLAlchemy is a wonderful library that allows to write SQL in a much more
comfortable Python syntax. Instead of writing

``` sql
SELECT name FROM placex WHERE osm_type = 'R' and osm_id = 3463
```

a Python syntax now looks like this:

``` python
sql = select(placex.c.name)\
        .where(placex.osm_type == 'R')
        .where(placex.osm_id == 3463)
```

This makes SQL inside a Python program much more readable. More importantly,
it makes it a lot simpler to write complex SQL queries. WHERE conditions can
be added or left out as required, subqueries clearly separated from the main
query and parts of the query may even be reused. Writing the search frontend
with SQLAlchemy was fun and debugging and improving the code in the future
will be much easier, too.

All this comes at a price that
it is fairly expensive to produce the actual SQL. Most of the time this is not
much of an issue because database requests are rare enough or the requests
themselves take so long that the overhead is barely noticeable.

Reverse geocoding queries in Nominatim do not fit this pattern.
A reverse request translates into up to 4 very short running
database requests measured in fractions of milliseconds. The overhead of
preparing the query is relevant in such a scenario.

### SQLAlchemy query caching

The maintainers of SQLAlchemy are conscious of the overhead their library
produces. That is why they have introduced compilation caching since version 1.4.
SQLAlchemy recognises when an SQL query with a similar structure is built.
Instead of recreating the textual SQL from scratch in such a case, it
reuses results from previous compilations.

When investigating how well this compilation caching works for Nominatim, it
turned out that it wasn't using the feature at all! The culprit was quickly
identified. Nominatim uses [GeoAlchemy2](https://geoalchemy-2.readthedocs.org)
for PostGIS support. The Geometry type that comes with the library
is not yet enabled to support caching yet. Given that almost every query in
Nominatim involves a geometry operation, the library effectively disabled
caching. Switching from GeoAlchemy2 to using our own custom Geometry type
solved the problem.

Now the cache was used but there were still some suspicious queries that should
have been cacheable but were never served from the cache. Tracking those down
required diving a bit deeper into the inner workings of the caching
mechanism. One of the queries revealed a
[bug in SQLAlchemy](https://github.com/sqlalchemy/sqlalchemy/issues/10042)
where wrong a badly computed cache key prevented caching. The friendly people
from SQLAlchemy have already fixed the problem in the meantime.

The other problematic queries revealed structural problems with how
Nominatim uses SQLAlchemy. The compilation cache only works well when queries
most of the time have the same internal structure. Nominatim's new algorithm for forward
search uses an SQL expression to compute how well the
result matches the input query. The formula was realised as a huge CASE
statement, whose structure is different for every single input. That
is poison for the cache. The formula is now hidden behind a custom
PostgreSQL function with two fixed parameters. A much more cache-friendly
solution that also makes the SQL queries more understandable for the human
reader.

Finally, it is also important to know that the VALUES statement is one of the
view that cannot be cached by SQLAlchemy either. It is fairly to replace the
statement with an array construct in PostgreSQL. Take for example the
following query with a VALUE subset:

``` sql
SELECT *
  FROM (VALUES (1, 'one'), (2, 'two'), (3, 'three')) AS t (num,letter)
```

a similar sub-table can be constructed with PostgreSQL's unnest function:

``` sql
SELECT *
  FROM unnest(ARRAY[1, 2, 3], ARRAY['one', 'two', 'three']) AS t (num,letter)
```

While the VALUES statement lists the static data row-by-row, the unnest
statement gives us a column-based view on the data. When compiling the
query in Python that makes little difference in the code.

With the caching mechanism fully functioning, reverse geocoding queries are
up to 20% faster.

### SQLAlchemy lambda statements

For very performance-conscious applications, the caching mechanism can be
sped up even further by using lambda queries. Take our initial SQLAlchemy
query example:

``` python
sql = select(placex.c.name)\
        .where(placex.osm_type == 'R')
        .where(placex.osm_id == 3463)
```

Even though the final query compilation can be cached here, the SQLAlchemy
functions `select` and `where` still need to be called every time the
code is passed. These calls can be saved by using lambdas. A lambda query looks
like this:

``` python
sql = lambda_stmt(lambda: select(placex.c.name)\
                            .where(placex.osm_type == 'R')
                            .where(placex.osm_id == 3463)
```

The code to build the query is thus hidden behind a function and SQLAlchemy
only needs to look up the compiled SQL that is produced by the code without
actually executing it.

Lambda queries are difficult to handle because not every construct is allowed
inside them. Furthermore, it is essential that the functions used inside the
lambda really produce exactly the same SQL construct every time. For Nominatim
it only made a noticeable difference for reverse geocoding. There are only a
handful of SQL queries and they are relatively short. By reorganising the code
slightly it was possible to have a single lambda statement like the one
above for all frequently used SQL queries.

If you think about using lambda statements in your code, carefully check
which SQL queries are a bottleneck and concentrate on the most frequently
used ones. It is not worth the effort to turn them on for all the code.

### Partial Indexes and prepared queries

SQLAlchemy offers another performance optimisation that ended up actually
slowing down Nominatim's queries: prepared queries.

Prepared queries are PostgreSQL's query compilation cache. Say you have
hundreds of queries that look up the name of a relation:

``` sql
SELECT name FROM placex WHERE osm_type = 'R' and osm_id = 3463
```

Then you can create a prepared statement

``` sql
PREPARE lookup_rel_name(id bigint) AS
  SELECT name FROM placex WHERE osm_type = 'R' and osm_id = id;
```

and send all your queries in a shorter form:

``` sql
EXECUTE lookup_rel_name(3463)
```

PostgreSQL will only need to parse the full query once and, more importantly
here, will also use a fixed query plan to execute the query. That can save a
lot of time for fast queries, where the actual execution of the query is
short compared to the time it takes to parse and plan the query.

Now assume we have a partial index over relations on our table:

``` sql
CREATE INDEX placex_relations ON placex(osm_id) WHERE osm_type = 'R'
```

This kind of index can be extremely useful for OSM data because we know
that there are very few objects of type relation. For the prepared statement
above, this index works very well. PostgreSQL sees that the query always
expects `osm_type` to be a relation and chooses the partial index.

The same query with SQLAlchemy syntax would look like that:

``` python
sql = select(placex.c.name)\
       .where(placex.c.osm_type == 'R')\
       .where(placex.c.osm_id == id)
```

When SQLAlchemy compiles the query, it cannot distinguish between constants
like `'R'` and a variable like `id`. Therefore it creates a prepared statement
like this:

``` sql
PREPARE lookup_rel_name(otype text, oid bigint) AS
  SELECT name FROM placex WHERE osm_type = otype and osm_id = oid;
```

At this point the query planner refuses to use the partial index because
to the query planner `osm_type` is now a variable which might or might not
match the partial index.

There are a few possible workarounds for this problem of partial indexes.
One could use views over the data contained in the partial index or
give SQLAlchemy the explicit hint that `R` is indeed a constant. Neither
approach is easy to maintain. For Nominatim, we went for raw SQL.
SQLALchemy will happily allow to mix its own syntax with textual SQL, so
that the above query may also be written as:

``` python
sql = select(placex.c.name)\
       .where(text("osm_type == 'R'"))\
       .where(placex.c.osm_id == id)
```

To reduce the danger of adding typos into the SQL, it can easily be wrapped
into a function, so that it is only written once in a well-defined place.


### Reverse performance after the optimisations

With all the described performance optimizations in place, it is time to
redo the experiments from the previous blog post. Given that the Falcon
web framework turned out to be the most efficient, we will only compare
numbers with Falcon under the hood. All other parameters of the setup
remain the same.

The first experiment was measuring how long a single reverse query takes
on average:

| Implementation                     | avg. query runtime |
|------------------------------------|-------------------:|
|  PHP                               |             6.3 ms |
|  Python (previous measurements)    |            13.7 ms |
|  Python (after optimisation)       |             8.1 ms |

We still haven't reached the performance of the PHP implementation but
it is now much closer to the penalty expected from the use of a proper
SQL compilation framework.

The next test was about distributing load over the available CPUs by
running 6 (the number of physical CPUs on the test server) and
12 (the number of virtual CPUs) workers and requests in parallel:

| Number of workers   |       1 |       6 |      12 |
|---------------------|--------:|--------:|--------:|
| PHP                 |  6.3 ms |  7.6 ms |  8.9 ms |
| Python (previous)   | 13.7 ms | 18.9 ms | 26.8 ms |
| Python (optimized)  |  8.1 ms | 13.8 ms | 18.8 ms |

The better query performance is also visible when running requests in parallel.
However, the optimizations have not helped to improve Python's rather bad
behaviour when running requests in parallel. That indicates that the problem
is less likely in SQLAlchemy itself but rather with PostgreSQL or with the way
Python and PostgreSQL processes interact. This still needs some investigation.

The overall maximum throughput for the test machine has increased from
around 480 requests/s with the original code to around 715 request/s with
the optimizations.

### Forward geocoding and performance

Most of this article was about performance of reverse geocoding. The
measures we have discussed also improve performance for forward geocoding.
However, given that a forward search takes about 5 times as long as a
reverse geocoding lookup, a speed-up of 5ms per query has much less influence
on the overall throughput.

When Nominatim handles a forward search query, it analyses the input and
comes up with a number of possible interpretations. It creates a SQL query for
each of these interpretations. If a query is difficult to parse, then this
can be as many as 50 requests to the database. Therefore, it has a much
larger effect to look at the internal algorithm to reduce the number of
interpretations Nominatim comes up with.


_Many thanks to [NGI Zero](https://nlnet.nl/entrust/) who are funding this
work on improving Nominatim._
