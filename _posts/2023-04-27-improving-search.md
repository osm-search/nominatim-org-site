---
layout: post
title: "Python Progress Reports: Refreshing the Search Algorithms"
author: Sarah Hoffmann (lonvia)
---

Forward search is the last and biggest part of Nominatim to get ported
to Python. Rewriting the search algorithm in Python was also an opportunity
to review its design and correct some of the long-standing short-comings.
This post looks into some of the changes made.

The secret to a good geocoding engine lies in its query parsing algorithm,
the part of the code that takes a free-form text and converts it into a
structured form that can be translated into SQL queries into the database.
Nominatim has always taken an unopinionated approach to make as few assumptions
as possible. Instead it creates a list of all possible interpretations of
the incoming free-form text and
tries all of them until it gets a result. This design makes searches a bit
slower because there are potentially dozens of database queries. Still, it works
very well with the heterogeneous OSM data with its many regional differences
and its evolution over time. So there is no need to change the principle.

One of the short-comings of the PHP implementation is that it works strictly
sequentially: first create a list of structured queries from and put them
in an order of best fit to the original free-form query. Then execute the
list until the database returns a result. Then recheck the results against
the original query to put them in an order. In practise, it is not always
possible to out the different interpretations of the free-form query into
the right order without seeing what results the database will yield. The
Python code therefore switches to a global measure of accuracy that
combines the likelihood how well the structured query matches the free-form
text with the likelihood how well the result from the database matches
the original query.

This unlocks some improvements to the search experience. Let's have a look
at two examples.

#### Full-name matches vs. partial matches

One of the most annoying features of Nominatim was that it would give a
hard preference to matches of the full name. To give you an example:
assume that OSM has the well-known city only tagged with `name=New York City`.
In addition there is a small restaurant in Chicago with `name=New York`.
In such a constellation a search for 'New York, US' would return the
restaurant because it is a perfect match (and well within the United States)
instead of the much better known city.

With the global accuracy measure, Nominatim is now able to search for
full-name matches and partial matches at the same time, giving all results
with partial matches a lower score. So there is still a preference for
perfect name matches but they won't prevent partial matches from appearing
up anymore. In the case of New York, the city would
still show up as the first result because the fact that it is very well known
gives the global accuracy an enormous boost.

#### Better matching of scripts

When Nominatim searches for a place, it doesn't use the name as it was
typed in the search box. It uses a form that is translated into Latin
script. This allows for some fuzziness when handling multi-lingual data sets.
It doesn't matter if you type 'manhattan', 'манхаттан' or 'マンハッタン'.
All of these searches will find [Manhattan](https://www.openstreetmap.org/relation/8398124).
The downside is that sometimes two obviously different names still match
up because the transliteration happens to be the same. There is a 
[long-standing bug report](https://github.com/osm-search/Nominatim/issues/2091)
that a search for 'Rømø', an island in Denmark, would consistently return
Rome as a result, just because Rome is very well known and happens to be
called 'Romo' in Esperanto.

With the new global accuracy measure it is possible to give results with
matching scripts a proper boost and avoid such confusion in the future.


### Readjusting the algorithm

Deciding how well a structured query or a database result matches to the
free-form text query is not a hard science. There are a lot of knobs and
screws that need to be adjusted through trial and error. The new global
accuracy measure comes with a whole different set of knobs and screws and
it will take a while to find the optimal adjustments.

To come to a useable initial setting, the
[geocoder-tester dataset](https://github.com/geocoders/geocoder-tester/)
comes in handy
This is a test set of almost 50.000 search queries. They are mostly addresses and
simple city name searches but also contain searches for POIs like
airports and museums. For the PHP implementation 72.8% of the tests pass.
In the initial Python implementation the success rate dropped to 68.3%.
After some tweaking, the success rate is now 74.6%, already a 2%
improvement over the old PHP code. 

