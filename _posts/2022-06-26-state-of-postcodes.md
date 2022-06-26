---
layout: post
title: "The state of postcodes"
author: Sarah Hoffmann (lonvia)
---

Postcodes are a curious thing. Not every country in the world has them.
But where they do, postcodes tend to play an important role for locating
areas. If you are in a country with postcodes, you likely know your home
postcode by heart and will be regularly asked for it. And because you have
to remember it, it makes sense to also use it when searching for places.
It's much shorter and more precise than a full address. Time to
take stock of postcodes in OpenStreetMap to see how useful they are
for geocoding.

### How Nominatim uses postcodes

Nominatim uses postcodes in two different ways. First of all, it needs to
make postcodes searchable. That means having a database of all existing
postcodes for every country together with its approximate location. Second,
it wants to be able to present a postcode for every result, even if the
found place doesn't have a postcode mapped. That means inferring the postcode
from the surrounding objects.


### Postcodes in OSM

Postcodes can be mainly found in two forms in OSM: as part of an address or as a
self-contained postcode area.

Postcode areas are multipolygons with a `boundary=postal_code` tag. They are
a rare occurrence as the map below shows. Only France, Germany and Hungary
have a full coverage with postcode areas. Belgium still has coverage for a
good part of the country. The coverage in other countries is so patchy that
it is fair to assume that the data is not up-to-date.

![Map of postcod areas](/img/postcode-area-overview.jpg)

So what about the rest of the world? There is still a lot of postcode
information found in the form of addresses.

Postcodes in addresses are tagged with `addr:postcode` and give us the most
accurate information about the postcode for a single spot on the map. There
are approximately 84 million postcode tags in the world and
[Taginfo](https://taginfo.openstreetmap.org/keys/addr%3Apostcode#map) shows
that they are neatly distributed over the planet.

![Distribution of addr:postcode](/img/postcode-points-taginfo-distribution.png)

In fact, they are dense enough that it is possible to infer a postcode for
most inhabited places on the planet, simply by looking up the closest
`addr:postcode` tag. The question is: how reliable are the postcodes mapped
in OSM?

### The quality of postcodes

To get an estimate of the quality of postcodes we can start with a simple
check: has the postcode the format that we would expect for the country.
Luckily, Wikipedia has a handy
[list of postcode formats in the world](https://en.wikipedia.org/wiki/List_of_postal_codes),
a perfect starting point for a quality check of OSM. It turns out that postcodes
are fairly regular. Most countries opt for a simple 4, 5 or 6-digit number.
A handful of countries adds the letters A-Z and optional spaces to the list
but that is it. The record for the longest postcodes are held by Iran and Ghana
with a length of 10 characters. You won't be surprised to hear that both
countries have a very high rate of formatting errors in OSM postcodes.

To check the OSM data, we just have to turn the Wikipedia list into something
machine-readable and have the computer compare it with the OSM data. You can
see the result of this analysis displayed below.

![Percentage of wrongly formatted postcodes](/img/postcode-format-correctness-worldmap.jpg)

Countries in green have less than 1% of postcodes with an error. Yellow means
that less than 10% of the postcodes are wrong. Countries in red have more than
10% errors. Countries that don't have postcodes have been left white.
To be fair, most of the red countries have introduced postcodes
very recently and therefore postcode coverage in general is very low at the
moment. The quality is bound to improve once postcode usage picks up in general.
The clear winners in the statistics are Iceland, Danmark and Liechtenstein.
Despite a very dense coverage with postcodes, not a single error could be found.

_Fun fact: there is a common kind of error with the `addr:postcode` tag that is
found in many countries: the tag contains the telephone area code instead of
the postcode. The age of the letter in writing is clearly coming to an end._

Overall only 0.14% of postcodes are wrongly formatted. That is quite
encouraging although it still doesn't really tell us how many postcodes are
wrong. A postcode might be well formatted but still have typos in them.
Finding such postcodes is much harder. However, we can get an estimate about
the number of errors by looking at Germany and France. For both countries we
have postcode areas and we can check the postcodes of address points against
them. For Germany, there are about 0.1% postcodes that do not match their area,
for France 0.7% postcodes are wrong. This is significantly more than there
are wrongly formatted postcodes but still so little that it is fair to say
that postcode data in OSM is quite reliable.

### QA for postcodes

Do you want to have a look at the typical errors and maybe even fix some of
them? The [Nominatim QA site](https://nominatim.org/qa/#map=2.48/0.00/0.00&layer=postcode_bad_format)
now includes a view that shows postcodes which do
not comply with their country's official format:

[![Nominatim QA site](/img/postcode-qa-site.jpg)](https://nominatim.org/qa/#map=2.48/0.00/0.00&layer=postcode_bad_format)


### Postcode filtering for Nominatim

The overall goal for doing the analysis in the first place was to see how
postcode handling can be improved in Nominatim. It turns out that filtering
suspicious postcodes is a very easy thing to do because postcode formats are
so very well regulated and are used quite consistently in OSM.

Starting with the next version, Nominatim comes with a
[sanitizer for postcodes](https://github.com/osm-search/Nominatim/pull/2757).
It filters out all the postcodes that do not comply with the official format
of the country. It will still show you wrongly mapped postcodes for the object
where you mapped them. But it will no longer use postcodes that "look wrong"
to infer the postcode on neighbouring objects or allow you to search for them.

In the long term, it would be nice to do more detailed consistency checks on
the postcodes. Postcodes are usually not assigned randomly but are grouped by
area. In France, for example, the first two numbers are always the same as the
department number. Hints like these could be helpful to find more mapping
errors. This, however, requires more sophisticated methods than a simple
regular expression check and is something for another blog post.
