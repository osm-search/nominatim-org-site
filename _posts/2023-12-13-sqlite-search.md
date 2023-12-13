---
layout: post
title: "Nominatim lite, part 2: Forward Geocoding"
author: Sarah Hoffmann (lonvia)
---

In [last month's post]({% link _posts/2023-10-25-sqlite-reverse.md %})
we've looked into using a SQLite database for reverse
geocoding. This is the second part of the post which looks into forward
search.

While reverse geocoding is mainly concerned with looking up objects by
geographic region, forward geocoding is basically a text search. SQLite
has some nice built-in capabilities for fuzzy text search. Unfortunately
they cannot be used because they are too different from Nominatim's internal
algorithms. To port the search to SQLite, we really need to port the index
used in PostgreSQL.

The text lookup in Nominatim works this way: all words that appear in a place
and its address are converted into an integer representation and then saved
in a huge table with two columns of integer arrays: one with all words with
the name of the place, one with all words from the address.

An incoming query is also converted into a list of integers. Searching is then
the equivalent of finding an entry in the search table that contains all
integers from the query. In PostgreSQL this is easily done using a GIN index
over the integer array columns.

SQLite implements neither integer array datatypes nor GIN indexes. To port
Nominatim search to SQLite both needs to be emulated.

### Custom integer arrays

Integer arrays can be simply converted to TEXT or BLOB types. For Nominatim
I went for a simple comma-separated list of numbers in a TEXT. This might
need slightly more space but is easier to debug. SQLAlchemy allows to
implement adaptors which make the conversion from a Python `int[]` to the custom
text field transparent and automatic.

Nominatim also makes use of some special operators for int arrays, in particular
_overlaps_(`&&`) and _contains_(`@>`). These also need to be implemented
in SQLite. There are no stored procedures in SQLite but the Python interface
allows to directly hook a Python function into the database. The implementation
simply uses the equivalent functions for sets. They proved to be the most
efficient.

### Reverse search index

The GIN index allows to look up the places that contain a given word. To
simulate it, a reverse version of the search table is needed: a table that
for each word has the list of places it contains. This is easily done. The
list of places can again be saved as a comma-separated list of place IDs.
Reversing the search table is a relatively expensive operation. We could not
use this technique on a Nominatim database that needs to be updated with fresh
data. It works here because the SQLite extracts are meant to be static.

A query usually does not consist of only one word. To find the places that
contain all the words of a query. Here a user-defined aggregation function
comes to the rescue:

```sql
SELECT array_intersect(places) FROM
  (SELECT places FROM reverse_search_name WHERE word IN (1, 2, 3))
```

The inner query finds the lists of relevant places for each word. Then
`array_intersect()` accumulatively computes the intersection of the results.
At this point, the Python implementation of the function really proved to be
a bottleneck. Some words like 'street' are very frequently used. Thus they
have a very long list of matching places. Just parsing such a list into a
Python set takes a significant amount of time. To avoid this penalty,
Nominatim implements a lossy version of this function: very large lists are
ignored if possible when computing the final result. This may result in a
few false positives (places that do not contain all the words) but those
can be filtered later by rechecking against the words in the original
search table. In fact, this is exactly the same behaviour as the PostgreSQL
GIN index has. It can also returned false positives. PostgreSQL simply
adds a recheck transparently for the user.

### Testing on real-world data

As in the previous post, a Germany extract and a database of admin boundaries
are used for testing. Here are the respective database sizes:

|                             | Germany | Admin  |
|-----------------------------|--------:|-------:|
| PostgreSQL                  |   34 GB |  19 GB |
| SQLite - reverse only       |   18 GB |  12 GB |
| SQLite - search and reverse |   30 GB |  19 GB |

The search tables increase the size of SQLite database significantly. However,
as before, there is no significant difference in the size between the
PostgreSQL and SQLite databases. The custom-made lookup table is as
size-efficient as PostgreSQL's GIN indexes.

#### Performance

It is difficult to test the forward search mechanism properly because the
free-text search allows a lot of different ways to write a query and each
might perform differently. For this test, we restrict ourselves to simple
tests looking for a well formatted address. For Germany, these are
housenumber-level addresses taken from the recently released POI set from
Overture. For the Admin set, we tests queries of the form `<city>, <state>, <country>`
using random examples from the same dataset:

Here are the results, given in requests per second:

| Extract | PostgreSQL | SQLite  |
|---------|-----------:|--------:|
| Germany |         22 |       3 |
| Admin   |        102 |      28 |

With an average response time of around 340ms for the Germany database,
the SQLite implementation is close to the limit where the response time
becomes noticeable to the user. This means that the SQLite approach for
forward searching is more interesting for smaller datasets.

### Where to go from here

Working with SQLite has been an interesting experiment in testing out the
limits of Nominatim. It has forced me to look closer into the code and
clean it up in some corners. I've also found and fixed some subtle bugs in the
search algorithm while working on the SQLite port as well as some places
where performance could be improved. So overall this was a win for Nominatim.

The biggest obstacle for making the SQLite database practical for everyday
use is still the size. 30 GB files are not as easily copied around as one
could wish. So there is some still some work to do. The code for creating
and using SQLite is available as an experimental feature in the master branch
now and will be part of the next release. You are welcome to play with it and
I'm looking forward to feedback.

_Many thanks to [NGI Zero](https://nlnet.nl/entrust/) who are funding this
work on the SQLite database._
