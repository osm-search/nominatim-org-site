---
layout: post
title: "Nominatim and the address tags"
author: Sarah Hoffmann (lonvia)
---

OpenStreetMap has a well defined schema how to add addresses into the
database. There is a [whole set of `addr:*`{:.tag} tags](https://wiki.openstreetmap.org/wiki/Key:addr)
that allow to specify every part of the address in a structured way.
When mappers have entered such an address, they naturally expect to be able
to search their place later by entering exactly the same terms in the
search box. Sometimes they are disappointed.

When it comes to creating addresses, Nominatim has so far mostly ignored the
`addr:*`{:.tag} tags and creates its own address instead. It takes
[place nodes](https://wiki.openstreetmap.org/wiki/Key:place) and
[administrative boundaries](https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative)
and computes for each place on earth its very
unique location. There are a couple of reasons why it is done this way.

First of all, not all objects in OSM have `addr:*`{:.tag} tags. So we cannot exclusively
rely on them to get the address of a place. In a way, the current mechanism is
the fallback.

Second, there is the question of translations. Many places in OSM
come with translations of their name tags. [London](https://www.openstreetmap.org/node/107775)
for example is translated into 155 languages. Naturally we wouldn't want to
duplicate this onto every single address in London. When Nominatim collects
the OSM places to create the address, instead of just looking at the `addr:*`{:.tag}
tags, it can make use of all these translation. This may not sound as important
when thinking about your local addresses but it becomes important when looking
for places in countries where you cannot read the script. English speakers
will surely prefer to see 'Forbidden City, Xicheng District, Beijing, China'
in the result list instead of 'Forbidden City, 西城区, 北京市, 中国'.

Finally, there is a technical reason for taking shortcuts with addresses.
There are currently about 100 million addresses mapped in OSM. If Nominatim
would save the full address for each of them, the size of its database would
double. Therefore it cheats a bit and only saves the full address up to street
level. When you search for an address like '3452 Main St, Crowtown', Nominatim
first looks up 'Main St, Crowtown' and then checks that it finds a house number
3452 that belongs to the streets it has found. This saves a lot of space but
gets us into trouble with the `addr:*`{:.tag} tags because those tags belong, of course,
to the house number not to the street.

Long story short, your carefully mapped `addr:*`{:.tag} tags have been ignored by
Nominatim all these years. No more.

Last week Nominatim finally has received the ability to [search for `addr:*`{:.tag} tags
on addresses and POIs](https://github.com/osm-search/Nominatim/pull/1965).
We still cannot add a separate address entry for each address. Instead the
algorithm works a bit differently. Nominatim checks for each address if the
names in the `addr:*`{:.tag} tags are covered already by the street the address belongs
to. If that is not the case, then the address gets its very own entry in the
search index containing the address elements from the street as well as the
content of the `addr:*`{:.tag} tags. That means that you can now find the address under
the name you have put into the tag and under the address that Nominatim has determined on
its own.

The change only has an effect on searching. You will find that the display name
still contains the address that Nominatim has computed itself. That is because
of the translation issue, I mentioned above. There is no good solution for it
yet.

As a side-effect of this change, Nominatim also no longer expects that a place
mentioned in `addr:place`{:.tag} exists. The `addr:place`{:.tag} tag is used for addresses
where the house number does not refer to a street. A classic example are small
villages that do not have street names but instead just sequentially number
their houses. Traditionally Nominatim would assume that `addr:place`{:.tag} contained
a typo and ignore it when there was no OSM place with the same name. Now it
just uses the name it finds. An example of such an address is
[Hainburg, Aussenliegend 13](https://www.openstreetmap.org/search?query=hainburg%2C+aussenliegend+13).
"Aussenliegend" loosely translates to 'outside the built-up area of the town'
something that we clearly would not map as a place in OSM.

These changes are already live on [nominatim.openstreetmap.org](https://nominatim.openstreetmap.org) and
[openstreetmap.org](https://openstreetmap.org). However, take note that we have not recreated the
whole database. So the new entries in the search index only appear, when an
address is touched because of your edits to OSM.[^1]

[^1]: Please don't do bogous edits just to see your address appear in the search
      list. There will be a database reimport soon.
