---
layout: post
title: "The Road to Nominatim 6"
author: Sarah Hoffmann (lonvia)
---
With version 5 Nominatim has finished the long transition from a simple PHP
frontend to a complex Python application. The change wasn't just about changing
the programming language but also about making Nominatim more flexible and
easy to use. With that out of the way, the question is what comes next. What
can you expect to see in version 6. The road for the next major version isn't 
completely paved out yet. This post outlines the major open issues and some
of possible next developments.

## Auto-completion and spelling correction

Search-as-you-type and some leniency towards spelling mistakes are without a
doubt on the top of the list of feature requests for Nominatim.
Search-as-you-type will require to change how the internal search indexes
are built and accessed. Nominatim's current search model
is not compatible with resolving incomplete queries. When it comes to
spelling correction, we are going to need a good model for estimating the
similarity between a query and the place names in the database. Simple
approaches like Levenshtein distance are difficult for a multi-lingual
database of proper names.

## Performance and Index Optimisations

A full planet database requires now more than 1TB in disk space. This means
that it reaches the limits of what can be done with of-the-shelf hardware. Worse,
the search indexes in our backing PostgreSQL database have grown to a size
where lookups are becoming noticeably slow. It is time to revisit our database
schema, see where tables can be optimised and trimmed down, and consider how
search indexes might be better organised differently to trim them down to what
is relevant for finding the right place.

## Complex OSM objects

Nominatim's entire processing pipeline is built in a way that it considers one
OSM object at the time. That makes processing and updating easy but it doesn't
fit well anymore with how data is modelled in OSM. We increasingly see detailed
mapping where multiple OSM objects make up a single real-world object that you
may want to find with search. To accommodate that Nominatim's processing pipeline
needs to be adapted, so that it can work with places that do not have a 1:1
equivalent in the OSM world. This also means that the output needs to change.
Every result of a search is currently tied to an OSM object. In the future,
it is more likely that you will get an abstract place description with references
to all the relevant OSM objects.

## Addresses as first-class citizens

[Physical addresses](https://community.openstreetmap.org/t/are-addr-tags-for-postal-addresses-only-or-for-locations-in-general/132565/44) are not considered searchable places on its own in Nominatim right now.
Addresses only appear as an attribute of a place and when you search for
an address, you will in fact get all place objects which happen to have the
address assigned. That can cause a lot of issues. For example, the more
detailed the mapping in OSM becomes, the more objects will be returned for
an address search, even though you would have expected exactly one result.
Inversely, there are sometimes OSM objects that have more than one address.
For example, some house entrances come with multiple house numbers. Or there are
houses where the address has changed and which you'd still want to find under
its former address. All this cannot be modelled in Nominatim right now.

To enable a true address search, addresses need to become first class citizens
in Nominatim that can be directly returned as a result. Places would of course
still keep their address attributes but those will only be references to
one or more address they can be found under.

## Complex categories

Every place in Nominatim currently gets a simple category which is derived
from the main tag of its OSM object. This puts some limitation on what kind
of category search Nominatim can do. For example, you cannot search for a
"vegan restaurant" or a "catholic church" because the main tags only
classify "restaurants" and "places of worship of any religion".

Another issue with the current classification system is that it is bad at
handling OSM objects with multiple functions (say, a hotel with an attached
restaurant mapped with the same POI node). Nominatim will simply duplicate
the OSM object in its database to cover both functions. That unnecessarily
blows up the database size.

So it is time to get a way from using OSM tags directly and introduce the
ability to define custom classifications. The idea here is to have hierarchical
categories (e.g. food.restaurant.vegan) and allow to assign an arbitrary number
of categories to each object.

---

These are the main open issues right now. If one of them sparks your interest
and you'd like to help moving them along, don't hesitate to get in touch.
The [discussion section on Github](https://github.com/osm-search/Nominatim/discussions)
and the [OSM community forum](https://community.openstreetmap.org/c/general/38/none)
are great places to start a discussion.
