---
layout: post
title: "New Feature: Entrance information"
author: Marc Tobias (mtmail)
---

Nominatim has recently added a new kind of details to its results: entrances.
This post explains what the new feature looks like
and why that is useful.

One of the important applications for geocoding is routing: you give the
router a start and a destination address and then expect it to find a route
in between. Start and destination address are usually sent to a geocoder to
convert them into a set of coordinates. The problem here is that geocoders
and routers have a slightly different view of the world: when a geocoder is
asked for an address, it will return the building that belongs to the address.
The router on the other hand only knows about the road network. So it has
to make an educated guess on which street you actually want to start your
journey. That usually works okay for smaller buildings but when it comes
to larger structures like parks or airports the outcome might not
be what you expect:

![Example routing from Chicago O´Hare airport](/img/2509-routing-chicago-ohare.png)

That's where entrances come into play. Instead of just returning the center
point of a location, Nominatim now adds the information where the location
can be entered and exited. An entrance is usually much closer to a street
from which the router can start the journey. Here is an example for
[Comox Airport, British Columbia](https://nominatim.openstreetmap.org/ui/details.html?osmtype=W&osmid=1353860602&class=aeroway):

![Nominatim entry for Comox Airport](/img/2509-comox-airport.png)

The blue circle describes the point that Nominatim returns to the router
per default. The red circles are the entrances. Using them, them router can
bring you right to the terminal.

To use the new information, add the
[`entrances=1`](https://nominatim.org/release-docs/develop/api/Search/#output-details)
parameter to your request. If the result has entrance information an
`entrances` field with a list of entrances will be added. For each entrance
you get its [type](https://wiki.openstreetmap.org/wiki/Key:entrance), coordinates
and any extra tags that might be available. Please give it a try, especially
if you are writing or using a routing engine, and
[let us know](https://github.com/osm-search/Nominatim/discussions)
what kind of information about the entrance is useful for you.

Entrances are widely mapped in OpenStreetMap but not much used so far. That
means that the tags around entrances are not well standardized yet. Making them
more visible and usable through Nominatim hopefully helps getting a wider
discussion going. There are a couple of limitations to the new entrance
feature that need more discussion:

* Entrances are only added for OSM ways. Multipolygons or sites that are
  mapped as OSM relations are currently ignored because it is unclear where
  to look for entrances. There is a proposal for a special `entrance` member
  for relations but it isn't widely used yet. Another option would be to look
  for entrances on `outer` members.
* When dealing with complex locations like shopping malls or airports, then
  finding the routing endpoint can become much more complex than just going
  to the main door. The right access point may depend on your mode of transport,
  the purpose of your visit (departure or arrival) and which parts of the
  location you want to access. This might need more fine-grained tagging in
  OSM or it might be solved through more complex routing algorithms or
  more precise geocoding.
* Entrances are of limited use, when the location you want to get to is part
  of a larger complex with special entrances. To reach an address in a gated
  community, you need to be routed to the guest entrance of the community,
  not the address directly. As before, there is no suitable tagging for
  OSM yet, to express such a fact.

Entrance output is available in preview on
[https://nominatim.openstreetmap.org](https://nominatim.openstreetmap.org).
Right now only entrances for recently edited data is available. You can
check in the details view of the Nominatim UI, if entrances for a location
are in the database: search for the location, then click on 'Details'.

_Many thanks to [@emlove](https://github.com/emlove) for implementing this
new feature and to [@mtmail](https://github.com/mtmail) for adding entrance
display to the Nominatim UI._
