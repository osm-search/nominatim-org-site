---
layout: post
title: "The Roadmap to Nominatim 5"
author: Sarah Hoffmann (lonvia)
---

The version 4.x series of Nominatim has seen some major changes to the code.
Both, the database import and the search frontend have received major
updates and refreshed algorithms. As we go into 2024, it is time to
consolidate and regroup. The goal is that the next version 5 is leaner
and even more easy to use than previous versions. This requires some
changes to how Nominatim is installed and used. Learn in this post how
this affects you and how you can upgrade.

## Changes in Nominatim 5

To make the rewrite of backend and frontend as smooth as possible for the
users, there is a lot of code in Nominatim right now, which still supports
much of the behaviour from before the rewrite. Getting rid of this code
not only makes Nominatim easier to maintain but also opens up the possibility
to convert it into a pure Python package.

### Removal of PHP

With the frontend renovatations finished, all major parts of Nominatim are
now written in Python, it is time to remove the last traces of PHP code.
With version 5 the PHP frontend code will be completely removed.

### Unbundling osm2pgsql

For many years Nominatim has shipped its own version of osm2pgsql. This was
because it didn't use the standard output of osm2pgsql but came with its
very own gazetteer output. Nominatim and the gazetteer code needed to be
in sync to function optimally. About a year ago, Nominatim has
[switched to osm2pgsql's flex output]({% link _posts/2022-11-28-towards-flex.md %}).
All customization can now be kept in simple Lua configuarion files within
Nominatim and used with an off-the-shelf version of osm2pgsql.
Version 5 will remove the ability to work with the former gazetter output
and require that you install osm2pgsql externally. This should not be a
big issue as osm2pgsql is well supported by all major distributions.

### Removing the legacy tokenizer

The final part to be removed in version 5 is the legacy tokenizer. The code
is a reminder from the rewrite of the import backend. It is far less
powerful than the ICU tokenizer, which has been the default since many versions.
The legacy tokenizer also requires a special PostgreSQL plugin which is
difficult to compile and run. Removing the legacy tokenizer will allow to
simplify the code in many places.

### Changing from CMake to pip

With osm2pgsql and PHP code removed, Nominatim becomes an almost pure Python
application. As such is will be possible to get rid of the heavy CMake
build system and switch to Python installation methods. Installing Nominatim
will be become as easy as `pip install nominatim` in version 5.

Without C code to compile, there is also nothing in the installation
process anymore that prevents Nominatim from being installed on
Windows and MacOS.

## Timeline

The list of changes might look large and intimidating but you don't need to
worry. All this will not happen suddenly and there will be ample time for
you to adapt your installation. Here is the timeline of planned versions
for next year:

* __4.4.x__ - _Q1 2024_

  This version will remove the experimental flag from the Python frontend
  and make it the default choice. If you have an existing installation,
  you should change from PHP to Python at this point.

* __4.5.x__ - _Q3 2024_

  This version deprecates the bundled osm2pgsql, the legacy tokenizer and
  the PHP frontend. It introduces the new installation method via pip
  while still offering the old CMake method of installation in parallel.
  The pip installation will also make it easy to use
  [Nominatim as a Library](https://nominatim.org/release-docs/develop/library/Getting-Started/).
  If you run automated installation scripts for your production machines,
  you should update them with this version.

* __5.0.x__ - _Q4 2024_

  The first major version of Nominatim 5 has all deprecated modules removed
  and can only be installed via pip.
