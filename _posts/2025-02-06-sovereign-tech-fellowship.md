---
layout: post
title: "Joining the Sovereign Tech Fellowship Programme"
author: Sarah Hoffmann (lonvia)
---

I'm happy to announce that I have been selected for the one-year pilot
of the [Sovereign Tech Fellowship programme](https://www.sovereign.tech/news/meet-the-sovereign-tech-fellows)
of the Sovereign Tech Agency.
The fellowship programme will support maintenance of Nominatim, Photon, osm2pgsql
and pyosmium over the next year.

Participating in an open-source software project like Nominatim or Photon
is not just about the implementation of fancy new features or clever
algorithms to improve performance or the user experience. A lot of work
happens quietly behind the scene: user questions need to be answered and bug
reports followed up. Dependent software needs to be monitored and updated
as necessary. The own code needs to be reviewed and polished regularly
to prevent it from ageing and slowly falling apart.
CI pipelines are a great tool for a maintainer but they do break with an
astonishing regularity and therefore need regular attention. Not to
mention that a CI is useless without a set of well-maintained tests.

With its new Sovereign Tech Fellowship programme, the Sovereign Tech Agency
recognises the importance of this maintenance work for the general functioning
of the open source ecosystem. 
The programme will financially support my day-to-day tasks of software maintainership:
responding to issues on Github, reviewing and merging pull requests, fixing
reported bugs and addressing security issues, improving documentation and tests,
preparing releases etc. On top of that there are some other not so glorious
maintenance tasks that are planned for this year.

Nominatim's import module relies on a datrie library, which has been
unmaintained for some years and [no longer compiles](https://github.com/osm-search/Nominatim/issues/3534)
with the newest GCC compilers. We need to find a solution to that by either
switching to a new library or taking over maintenance. A similar fate is likely
in store for the testing library [behave](https://github.com/behave/behave).
With the latest stable release from 2018 and very few activity since, it is
unclear how long it will remain functional with new versions of Python.

Photon has seen the move to OpenSearch 8 last year. This transition is far
from finished. For example, there is still no proper support for using an
external instance of OpenSearch instead of the embedded one. And
ElasticSearch/OpenSearch itself has also seen some improvements in the last
three versions we have skipped. It's well worth investigating how geocoding can
benefit from them.

These will, of course, not be the only things happening in 2025 for Nominatim and
Photon. There will also be shiny new features and I have some ideas for
improving performance and how to better handle the increasing complexity of
OSM data. However, none of this can really happen, if the basis isn't there and
the general maintenance isn't cared for.

Many thanks to the Sovereign Tech Agency for this great opportunity and the
recognition of the importance of maintenance work for software.

_If you want to support development and maintenance of Nominatim, too, please
consider becoming a [Github sponsor](https://github.com/sponsors/lonvia)._
