---
layout: post
title: "Happy new year"
author: Sarah Hoffmann (lonvia)
---

The end of last year saw the [release of the 3.6.0 version](https://github.com/osm-search/Nominatim/releases/tag/v3.6.0)
of Nominatim. It concludes
last years effort to improve the address information that is returned to you
when you search for something. We have gradually changed how Nominatim
organises address information and how it interprets information on OSM place
nodes and administrative boundaries. The new system also takes into account
that today the existence of administrative boundaries is rather the norm in OSM
than the exception. When the original code was written years ago, this was
still different. There is still some work to do to look through the data
of each country and adapt the ranking system now in place to the local customs
but these are more smaller changes we can do gradually.

So where to go from here? I'm happy to announce that the
[NGI Zero Discovery](https://nlnet.nl/thema/NGIZeroDiscovery.html) fund has
accepted a proposal to partially support the development of Nominatim over
the coming year. The main focus of this work will be on adding language-awareness
for query parsing and place name interpretation. The goal is to improve the
quality of search results across all languages but especially for languages
that use letters beyond a simple A-Z. We want to get to an architecture where users
can more easily contribute their local knowledge to improve searching in their
language or region. And it is worth mentioning that reworking the query parsing
is also an important step towards the much demanded fuzzy search.

Here is a more detailed list of steps to be tackled in this project:

* __Introduce standard libraries for normalization.__ Normalization is the
  process of removing features of a query or name string that are not relevant
  for search. We plan to replace the very simple hard-coded character lookup
  table with a more flexible and standardized approach using libicu.
* __Configurable abbreviation handling.__ Abbreviations (like ‘st’ for street)
  are very common in geographic names. Nominatim has a relatively short
  hard-coded list of abbreviations which is applied with little regard for
  context. We want to make abbreviations configurable for an installation and
  allow to add annotations (like language and grammatical structure).
* __Develop a show-case language-sensitive parsing algorithm__
  Finally we want to put everything together and creating a language-sensitive
  parsing component for Nominatim. The goal is to use this as the new default
  parsing algorithm but also for it to be usable as an example for users who want
  to create their own extensions.

In addition, there are some secondary goals for the project:

We finally want to make Nominatim packagable for distributions. You shouldn't need to
have the source tree lying around on your production machine. Setting up the
software should become as simple as `apt install nominatim`.
We want to get away from the monolithic, hard-coded architecture and make it
easier to extend Nominatim and customize it for your particular use case.
And while the documentation is slowly growing on [nominatim.org](https://nominatim.org)
there is always room for improvement to make it more detailed and accessible for
everybody.

There is a lot of work to be done and you can help to speed up development by
becoming a supporter yourself. Have a looked at the [funding page](/funding)
to learn about the different options to support Nominatim.
