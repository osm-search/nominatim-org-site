---
layout: post
title: "Introducing the Nominatim command-line tool"
author: Sarah Hoffmann (lonvia)
---


Installing and running Nominatim has for a long time involved handling a couple of PHP scripts. Those scripts will go away with the next release. A new one-stop tool 'nominatim' is going to take their place. Installation, updates, maintenance can all be done using the same simple command-line tool. Switching tools is also a great opportunity to clean up the historical baggage that has piled up in the existing scripts. This post describes some of the changes that come with the new tooling.

### Reorganising the interface

The nominatim command-line tool will follow the command-style interface that
has become very popular with git:

    nominatim <command> [<parameter> ...]

There is no 1:1 mapping between new commands and the old-style PHP scripts.
Instead we have tried to clearly distinguish between the different tasks in
the life-cycle of maintaining a Nominatim installation: imports, updates,
maintenance and querying.

### Simplifying the import

The old `utils/setup.php` script that was responsible for setting up a new database
offered a lot of options to run all kinds of steps of the process separately.
Most people won't really need that, so the nominatim tool will greatly simplify
the process. It offers only two options: run a complete import or try to
continue an import that was interrupted for some reason. This will hopefully
simplify the task of setting up a new database for the average user.

Cleaning up the import script also allows to offer more advanced installation
models in the future like running an import without super-user rights to the
database.

### Command-line query interface

As a completely new feature, the new 'nominatim' tool adds function to query
the database directly from the command-line. The functions use 'php-cgi'
under the hood to call the same PHP scripts that also drive the webservice.

With these new functions you no longer need to go through the hassle of setting
up a web server for your own Nominatim installation when you just want to
do some local batch geocoding. Just run your queries against the command-line
using exactly the same API functions as you know from our webservice:

    ./nominatim reverse --lat 47.14267 --lon 9.52429 --zoom 12 --format geocodejson
    {
        "importance": 0.555694357690254,
        "boundingbox": [
            "47.0870567",
            "47.1940393",
            "9.4950763",
            "9.6116778"
        ],
        "display_name": "Vaduz, Oberland, 9490, Liechtenstein",
        "category": "boundary",
        "osm_id": 1155956,
        "address": {
            "county": "Oberland",
            "country_code": "li",
            "town": "Vaduz",
            "country": "Liechtenstein",
            "postcode": "9490"
        },
        "lat": "47.1392862",
        "place_id": 108937,
        "name": "Vaduz",
        "place_rank": 16,
        "lon": "9.5227962",
        "type": "administrative",
        "licence": "Data © OpenStreetMap contributors, ODbL 1.0. https://osm.org/copyright",
        "addresstype": "city",
        "osm_type": "relation"
    }

### Switching to Python

The command-line interface is also the first step towards the bigger goal of
slowly moving Nominatim towards Python. PHP has done an okay job for us until
now but it does impose limitations for the future development of Nominatim.
Python has a better support across operating systems and distributions, in
particular when it comes to installing third-party libraries. It
comes with a lot of batteries already included and for those parts that are
missing, there surely is a library to be found. We also hope that the switch
to Python makes it easier for the community to contribute.

The switch won't be immediate. At the moment, the framework for the command-line
tool is completely written in Python but it still calls into PHP for many of
the actual functions. That gives us the possibility to port the functions step
by step. The query part will remain in PHP for the time being.
