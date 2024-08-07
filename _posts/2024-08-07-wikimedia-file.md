---
layout: post
title: "New Wikimedia-based scoring file available"
author: Marc Tobias (mtmail)
---

Nominatim tries to assign each place in its database a base "importance"
score number to answer the question "If 30 places have the name 'Berlin',
which one is the most likely a user meant?" For Berlin that's the one in
Germany. We humans say "of course" but that's not how computers work.

Looking at a places' type (city vs village), size, OpenStreetMap tags,
population all have disadvantages, usually simply lacking a good data
source for the whole world. We even tried looking at how often tiles
were loaded for regions on tile.openstreetmap.org (Google Summer of Code
project 2022) but that's not granular enough.

Wikipedia turned out to be a good approximation or "importance". Basically
if a place has a Wikipedia article, and how many other articles link
to it? And we can turn that into a single number.

As early as 2014 (version 2.2) Nominatim had the option to imported
additional scoring files. Those files were created from Wikipedia
metadata. First using their pageviews, later based on links between
Wikipedia article, links between Wikipedia projects (languages), then
including redirects and now even taking Wikidata into account.

The scoring file contains language code, Wikipedia article
title, Wikidata id, redirect titles and a score number for 17 million
titles. Nominatim matches the title against place names.

Many places in OpenStreetMap data already have the
[wikipedia](https://wiki.openstreetmap.org/wiki/Key:wikipedia)
and [wikidata](https://wiki.openstreetmap.org/wiki/Key:wikidata)
tags. That's helpful for us, please continue to add those. On Wikipedia
many places
[contain coordinates](https://en.wikipedia.org/wiki/Wikipedia:How_to_add_geocodes_to_articles).
Again that's helpful: we can determine if an article is about a
place instead of for example a movie title, band name or
[pastry](https://en.wikipedia.org/wiki/Krapfen_(doughnut)).

Over the years creating the scoring file became unmaintained while
the data to process grew massively. Just English Wikipedia contains
900 million links! The metadata for the 40 largest languages
is 40GB compressed (about 90% compression rate). We had a major rewrite
of the processing during the Google Summer of Code 2019 project
but it loaded all data into a database. Processing took several days
each time, was error-prone and we rarely ran it.

In the last year we got the processing down to a manageable 12 hours.
This will allow us to publish updated importance file much more frequently.
We have also streamlined the format and publish it now as a simple CSV file.
If you have other uses besides geocoding in mind, you are welcome to
use it. You can read the full details about how the file is made and
what it contains at
[https://github.com/osm-search/wikipedia-wikidata#readme](https://github.com/osm-search/wikipedia-wikidata).
The updated file can be downloaded at
[https://nominatim.org/data/wikimedia-importance.csv.gz](https://nominatim.org/data/wikimedia-importance.csv.gz).

Nominatim itself will receive full support for reading then new CSV file
format in the upcoming version 4.5.
