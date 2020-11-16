---
layout: post
title: "Place nodes and boundaries"
author: Sarah Hoffmann (lonvia)
---

Geocoding doesn't just mean to throw a number of place names into a database
and then search for them. To make search truly useful, the geocoder needs to
add some context to each place, commonly referred to as the place's
address. In the past year, we have gradually reworked how Nominatim determines
the address of a place going from an unstructured to a more structured approach.
This post describes how the new algorithm works and what that means for the
places you have mapped in OSM.


The address of a place has two functions in geocoding. It is very important to
help narrow down a search: 'I mean the Main St in Lyons, Colorado, not the one
in Alta Loma, California.' It is also used to present you a meaningful list
of results so that you can choose the right one, just like the
[osm.org](https://openstreetmap.org?query=Alta Loma) website does.

Finding possible candidates for an address is fairly easy.
Just get the names of all places around your place of interest. Those very
roughly correspond to the terms somebody might use to narrow down their search.
To display the address, just string together all the names of the surrounding
places. And indeed, in a nutshell, that's what Nominatim has been doing for many years.
It works but doesn't always get you the best answer. The results can be long and
contain irrelevant names. What you really want to do is build a structured
address for your place, something of the form: 'place A is in suburb B,
city C, province P in country Neverland.' With structured addresses we can
format our results in the same way you would habitually put an address on
a letter. That greatly improves readability. Structured addresses are also useful
for finding the most relevant search. When looking for 'Amalienstr, Karlsruhe'
it is much more likely that you mean the street in the city of Karlsruhe than
the one in Ettlingen in the county of Karlsruhe.

### Address context in the OpenStreetMap data

There are three features in OSM data that are suitable candidates for
creating an address: address tags, place nodes and administrative boundaries.
[Address tags](https://wiki.openstreetmap.org/wiki/Key:addr) are simple and
obvious to use. However, not each object in OSM has them, so a fallback is
needed.

[Place nodes](https://wiki.openstreetmap.org/wiki/Key:place) are seemingly
perfect for structured addressing. They have a name and a type: city, town,
village etc. The problem is that reality turns out to be more messy and
tagging in OSM is not universally consistent. Two place nodes of the same
type do not necessarily translate to the same thing in a structured address.
For example, `place=village` is usually used for
[independent small villages](https://www.openstreetmap.org/node/293132236),
but you'll find it just as often being the 
[suburb of a larger town](https://www.openstreetmap.org/node/5565121214).
It makes sense from a mappers point of view.
These 'villages' used to be independent until got 'eaten up' by the ever growing
main town. They might still have their traditional village square and often
are even referred to as 'Village So-and-so'. It might quack like a village
but it is still a suburb or neighbourhood in terms of addressing.

The other issue with place nodes
is that they are point geometries without any information how far they extend.
When two place nodes of the same type are close to the point of interest,
Nominatim can only make an educated guess which one to include in the displayed
address.

Administrative boundaries are nicer. They have a well defined area that clearly
spells in or out[^1]. They also have a clear hierarchy, the admin_level.
Unfortunately, admin_levels are not easily assigned to a place type because
there is no 1:1 relation between admin_levels and place types.
Take for example Poland. The admin_level=6 in Poland usually designates a
county. However, some cities like Warsaw or Krakow have a county status in
terms of administration. They appear therefore on admin_level=6, while we would
still like to designate them as a city in our structured address. This is not
an unusual situation. In fact, cities with special status exist in almost
every country on earth. Luckily, OSM has the habit of assigning
both an administrative boundary and place nodes to many places, which makes it
fairly easy to detect that particular situation.

[^1]: Well, mostly. In some countries like the US, administrative areas are
      not the same as the area the post office or, in fact, any sane person
      would define for that place. But that is again something for another post.

### Bringing structure into OSM tagging

This brings us to the algorithm that Nominatim uses to determine the structured
address. This part is fairly technical, so feel free to skip over it.

Nominatim starts out with defining its own system for the address hierarchy,
the _address ranks._ This is a numerical value between 4 and 30 which then
can be translated back into a fixed part of a structural address. The smallest
level 4 corresponds to a country, the largest level 30 designates a POI or
housenumber. The documentation has a
[table of address ranks](https://nominatim.org/release-docs/develop/develop/Ranking/#address-rank)
with the full list of translations into address function.

Next, each OSM object that can be used as address context, gets assigned an
address rank like this:

1. Take all administrative boundaries and assign them an address function based
   on the admin_level. There is a default assignment but if your country uses
   admin_level in a different way, Nominatim can change this assignment on a
   per-country basis.

2. Try to match the boundaries with place nodes. Matches are made when
   place nodes are 'label' members in the boundary relation, have the same
   wikidata tag or, in restricted cases, have the same name. If that does not
   work, check if the boundary has a place tag that defines what kind of
   place it is.

3. If the matched place type does not fit the address function start shifting
   the address rank of the boundary. The important rule here is that the admin
   level hierarchy is kept as is. The rank can only be decreased when there is
   no other boundary in the way. When the rank increases, then all boundaries
   inside it with a higher admin_level automatically increase their rank as well.
   This latter rule ensures that places like Warsaw get the right address and
   all containing boundaries remain part of the city.

4. Take all the place nodes that are not linked and assign them an address rank,
   thus putting them into the hierarchy. Again this assignment can be defined
   on a per-country basis, which is useful especially for less well defined
   place types like 'municipality'.

5. If a place node now finds itself in an administrative boundary with
   exactly the same address rank, then this place node's rank is increased.
   This solves the problem of the 'suburb villages'. An independent village
   usually finds itself in a county boundary and therefore can keep its default
   rank as city in the address sense. If the `place=village` is inside a city
   boundary (which already has the address rank of a city), it gets degraded to
   the address level of a suburb.

Once every boundary and place node have an assigned address rank, creating an
address for a place boils down to finding the relevant once close by and sorting
them by their assigned address rank.

### What it means for mapping in OSM

Nominatim tries its best to take into account the mapping habits and make the
best of local particularities. Still you can help to make life easier for
geocoders like Nominatim. Here are a couple of hints:

* When you map an administrative boundary and a place node, make sure to link
  them. Either add them with role 'label'[Do not use 'admin_centre'. This
  designates the seat of the administration which may or may not be the same
  entity as the boundary.] or make sure they have the same wikidata tag.

* Add place nodes or place tags for administrative boundaries where the
  administrative level is not a clear indicator what the place type might be.

* Review the free place nodes in your area and check that they are used
  consistently. Within a city, don't mix place=suburb, place=village, etc. if
  they should refer to the same level of hierarchy. Conversely, if there are
  different levels like suburb and neighbourhood, make sure to use different
  place types for them. The same is true for rural areas. The distinction
  whether hamlets are just suburbs of a village or independent is very difficult to
  make with today's OSM data.

* Try to complete administrative boundaries for your area. If there are no
  formal boundaries, you can also map `place=*` items as areas.

These changes are already live on [nominatim.openstreetmap.org](https://nominatim.openstreetmap.org) and
[openstreetmap.org](https://openstreetmap.org). However, they only affect
newly changed data, while we are still busy ironing out the last kinks in the
implementation. Once this is done, the database will be re-imported so
that all data follows this new scheme.
