---
layout: post
title: "Security Audit for Nominatim"
author: Sarah Hoffmann (lonvia)
---

The NLNet foundation offers a number of service for projects that it sponsors.
One of those services is a security quick-scan of the software. The friendly people at
[RadicallyOpenSecurity](https://www.radicallyopensecurity.com/) (ROS) had a look at
the Nominatim codebase to evaluate it in terms of security.

The focus of the security scan was put on the import side of Nominatim. We
briefly discussed the threat models and quickly agreed that the biggest threat
to Nominatim is with problematic OpenStreetMap data. As everybody can edit
OSM data at any time, it is easy to insert data that might trip up downstream data
consumers. There doesn't even need to be malicious intent. Just recently
somebody uploaded a relation with more than 200.000 members because of a simple
editing accident. It caused quite a few tools to fail because they were not made
to handle such large relations.

ROS focused on checking the new Python processing code and the SQL codebase.
They found no obvious vulnerabilities that require any immediate action.
They report that SQL provides a very small attack surface in itself, while the
Python code uses a defensive programming style that minimises the data with
which the code interacts. SQL queries are created in a safe manner using the
psycopg2 library and when subprocesses are spawned, it is properly handled.

We did also discuss another attack vector that could comes from manipulated
OSM data files, the planet file or extracts that are provided by external
sources. In that case it is not the data itself that is changed but the file
is formatted in a way that breaks the software that reads the files. Nominatim
delegates parsing of OSM data to [osm2pgsql](https://osm2pgsql.org). Thus
such a threat model was out-of-scope for this audit of Nominatim. Still,
ROS came to the conclusion that a closer look into osm2pgsql might well
be worthwhile given that they are also in
widespread use for processing OSM data outside Nominatim.

This leaves the PHP search frontend of Nominatim. This is the oldest part of
the software and it is obvious even for the untrained eye that it does not
adhere to modern standards of security-aware programming. SQL queries are
hand-crafted strings and there are few unit tests of the code. This is one
of the reasons why we want to replace the frontend with more modern Python
code in over the coming year. With the code being already scheduled for
demolition there was not much sense in a deeper audit. ROS only did a quick scan
using [sqlmap](https://sqlmap.org). They couldn't find any SQL injection
vulnerabilities or attack vectors through arbitrary user input. So the code
existing code does not need any immediate changes either.

To further the goal that Nominatim is a trust-worthy software we have already
last year established a
[policy for responsible disclosure](https://github.com/osm-search/Nominatim/blob/master/SECURITY.md).
There you can also find a list of supported versions and how long they
receive security updates.
