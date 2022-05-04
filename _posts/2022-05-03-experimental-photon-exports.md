---
layout: post
title: "Experimental Dumps for Photon"
author: Sarah Hoffmann (lonvia)
---

We've made it easier for you to test out the latest features of Photon.
The [download server for Photon dumps](https://download1.graphhopper.com/public/experimental/)
now offers experimental dumps made from the latest development version of Photon.

Thanks to the support of [Graphhopper](https://www.graphhopper.com/) we have
been able to offer weekly dumps of the Photon database. These make it really
easy to get your own instance of Photon running. Download the the dump,
unpack it, start up Photon and you have your own private geocoder.

For those of you, who would like the easy handling of the dump but would like
to try out the latest new features of Photon from the development branch,
there are now [experimental dumps](https://download1.graphhopper.com/public/experimental/).
These are made weekly using the latest development version of Photon.
Like with the regular dumps for the stable versions, there is
a planet dump available as well as country extracts.

This is mainly for people with a bit of system adminsitration experience but
without the resources to set up a full Nominatim installation to make their
own dumps. You still need to check out and compile your own Photon from the
latest version from Github to use the dumps. The main directory contains
a `VERSION` file, which tells you which commit of Photon was used to create
the dumps. Usually though, the latest Photon version and the latest dump
should work together. 


The first new feature, you can try out with the experimental dumps, is the
[new layer parameter](https://github.com/komoot/photon/pull/667)
recently contributed by [Matthieu Robin](https://github.com/macolu) (thank you!).

You can now filter results by their address level, e.g. state, city, street, house.
This can for example be useful if you know that your users won't search for
exact addresses or POIs and only want to offer place names as suggestions.

The new `layer` parameter works for forward and reverse geocoding. It is currently
only available together with the experimanetal dumps and the developement version
of Photon.
