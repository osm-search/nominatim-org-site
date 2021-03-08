---
layout: post
title: "Release preview: Installation and Software Updates"
author: Sarah Hoffmann (lonvia)
---

In our mission to make Nominatim easier to install and use, there are two more
features we are working on for the next release: making Nominatim installable
and adding automatic migrations.

Anybody who has tried to set up their own Nominatim import has probably
noticed that Nominatim needs to be run in-place: download and
unpack the source code and run everything from there. That is admittedly a
comfortable arrangement for a developer but less so for a user that just wants
to run their own Nominatim service.

To make Nominatim an installable software
like any other, it was necessary to first cleanly separate the parts in the code
that are generically usable from those that are tied to a specific Nominatim
database import. The latter part obviously includes configuration files and
optional extra data like postcodes. In addition, there are parts of the code
which are strongly tied to the specific import. The most prominent example is
the custom PostgreSQL normalisation module that ships with Nominatim. The next
release introduces the notion of a _project directory_, a directory that
collects all the data used for one specific import.

With the import-specific data out of the
way the remainder of the code can then be installed in standard OS locations
with [nominatim tool](https://nominatim.org/2021/02/25/nominatim-tool.html)
providing all the commands for manipulating your database and project directory.

Installation is one part, another important part is upgrading the software.
Every new version of Nominatim brings some changes of the database schema. To
be able to update to a newer software version without having to endure days of
reimporting the database, _migrations_ are needed: instructions how to get from
an old database schema to a new one without a reimport.
In previous releases, we have usually provided documentation
[how to migrate to newer versions](https://nominatim.org/release-docs/latest/admin/Migration/)
manually. Starting with the next release, this tedious task will be taken over
by a new migration command. Not only will this make the work easier for
database administrators, it also means that we can think about more complicated
changes to the database schema in the future. As long as a migration is provided,
anything is possible.

