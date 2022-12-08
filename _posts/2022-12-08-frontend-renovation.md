---
layout: post
title: "Frontend renovations"
author: Sarah Hoffmann (lonvia)
---

The search frontend code is one of the oldest remaining code parts of Nominatim.
I'm happy to announce that [NGIZero Entrust](https://nlnet.nl/project/Nominatim-lib/)
has accepted a proposal to refurbish this part of Nominatim. The goal is modernize
code and algorithms and make
Nominatim ready for another use-case: offline geocoding.

### Switching from PHP to Python

As part of the rewrite the frontend will be switched from PHP to Python. Some of
the reasons for this change in language we have already discussed when
[talking about switching the backend to Python]({% link _posts/2021-02-25-nominatim-tool.md %}):
better support across operating systems and distributions, better library
support and a wider contributor base. Python has now a pretty stable interface
for coroutines through [asyncio](https://docs.python.org/3/library/asyncio.html).
This has a lot of potential to speed up a query-heavy application like Nominatim.
The new frontend will be designed as an asynchronous library from the start.
SQLAlchemy provides an excellent framework for rendering SQL which will make
the code not only more readable but also more secure against SQL injections.
With the move to Python
the Nominatim server will also become stateful. This opens up many possibilities
to introduce more complex query parsing routines that rely on more complex
data structures.

### Taking geocoding offline

Conventional wisdom has it that geocoding is a classic service that only
makes sense to be offered as an internet service. Too much data, too much
preprocessing computation to make sense to run for one consumer alone.
Yet, there are a lot of people who have installed their own instance of
Nominatim. Economic reasons may be a strong motivating factor. Another
important advantage of doing geocoding offline is privacy. Do you really
want to send the full address list of your customers to some random server
in the internet?

Nominatim already tries to make a local setup as easy as possible
with a simplified installation process and approachable documentation.
With the frontend renovation we want to go one step further. Until now,
Nominatim was a classic web service software: to use your own instance, you
needed to run it behind a webserver. The new Python API will be designed
to make it possible to cut out the middle man and use Nominatim functions
also directly in form of a Python library.

Even then, Nominatim will be difficult to handle as long as it depends on a
full-scale PostgreSQL database. As part of the NGI project, I will look into
running Nominatim on a SQLite database. I will explore if SQLite has the
features and performance needed to use Nominatim's geocoding algorithm with
the simple file-based databases.

### The road ahead

In the next months I will gradually introduce the new Python search frontend
on the master branch. Because the frontend is completely new code, it will be
possible to publish the new code as it emerges without breaking the old PHP
frontend. You are welcome to give the new code a try and leave feedback.
