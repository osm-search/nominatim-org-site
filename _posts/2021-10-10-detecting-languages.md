---
layout: post
title: "Detecting languages"
author: Sarah Hoffmann (lonvia)
---

In the [post about abbreviations]({% post_url 2021-07-03-abbreviations %})
we briefly touched on the importance of knowing
the language of the names you are looking for. The literature on search strongly
agrees on that. The most effective techniques for searching (stemming,
stop words, compound analysis etc.) strongly rely on knowing about some
fundamental properties of the underlying language. Geographic search is no
different. Every language has its own particularities when it comes to
expressing addresses. So how do we handle this with OpenStreetMap data?

Luckily for us, OpenStreetMap already knows about the concept of name
translations. To add a name in a different language to a place, simply use
the `name` tag (`short_name` or `old_name` or any of the other name variants)
and add a suffix with the two- or three-letter language code. Famous places
like [London](https://nominatim.openstreetmap.org/ui/details.html?osmtype=R&osmid=65606&class=boundary) come with dozens of translations,
among them such exotic languages as Neapolitan or Nahuatl[^1]. The language
suffixes are also consistently used in places where multiple languages are
spoken. For example, we have language information for [every street in
Brussels](https://nominatim.openstreetmap.org/ui/details.html?osmtype=W&osmid=8083619&class=highway).

[^1]: The OSM community drew the line when someone started adding translations
      for [Klingon](https://wiki.openstreetmap.org/wiki/Key:name:tlh).


While translated names are useful, they still make up a very small part of
the place names that can be found in OSM. Most feature simply have a `name` tag
without any suffix. Per convention, these name should be in the local language.
Given that we know the location of the place, it should be easy to conclude
which language the main tag is it. Nominatim already has a [list of languages
spoken in each country](https://github.com/osm-search/Nominatim/blob/master/settings/country_settings.yaml), which it uses to return the place name in the right
language. We can use this also to tag the language of a name.

As always with OSM data, things are not that simple.

#### Multi-lingual countries

First of all, it is of course a bit naive to assume that exactly one language
is spoken in each country. Even using a more fine-grained regions doesn't help
very much. There are enough regions where many languages are in parallel use.
Fortunately, there is no need to determine exactly one language for our names.
If multiple languages are spoken in a country, then we can simply take the name
and analyse it multiple times, once for every language. There will be a couple
of false results but still far less than our language-unaware algorithm
produces now. As long as the language list for the country is complete, the
right result will be in there as well.

#### Non-local name tags

OSM mappers don't always follow the rule to use the local names. This used to
be a problem in areas with little or no local communities but lots of Western
visitors, for example [in Thailand](https://www.openstreetmap.org/#map=17/7.79288/98.32160).
Thankfully, these cases are harder and harder to find as OSM slowly matures.

Things are a bit more difficult with places that explicitly give themselves
foreign names. Many of the hotels in the above example likely really have an
English name to accommodate the language habits of tourists.

It is an interesting linguistic question if speakers treat these names really
like being a foreign-language word or simply like an odd proper name. In the
first case, language rules for the foreign language would need to be applied,
in the latter case not.

In the end, it's a case by case basis for each country if the "tourist" language
is prevalent enough to add it to the list of default languages considered for
the name tag.

#### Mixed-lingual names

The last and most difficult class of name tags are those, where multiple translations
of a name appear in the `name` tag. This is common practise in countries with
multiple official languages to make sure that all official names of a place
get rendered. Again, I refer to the example of
[Brussels](https://www.openstreetmap.org/#map=18/50.85321/4.37467)
where every street name comes in two variants.

Mixed-lingual names are mainly an issue for searching because they take up
space in the search index without being of any use. Nobody will ever search
for "Casablanca ⴰⵏⴼⴰ الدار البيضاء " and the name of each language will almost
always be available in a language-specific `name:xx` tag. So in terms of search,
the goal is to stop these names from being added to the search index.

There is a [helpful wiki page](https://wiki.openstreetmap.org/wiki/Multilingual_names)
listing all countries that follow this practise and the exact format of the
name. The list shows that there is not one established standard but four:

1. `<name1>` / `<name2>`
2. `<name1>`/`<name2>`
3. `<name1>` - `<name2>`
4. `<name1>` `<name2>`

The record is held by Italy which manages to use a different standard for each
of its three multi-lingual regions. The once common practise of adding a
transliteration for Non-Latin scripts in brackets has luckily been largely
abandoned. Still, the different standards make detection of such
mixed-lingual names rather expensive. The only reliable means consists in
matching the name against the language-specific ones to make sure it is really
a duplicate of some of the other names.

### Putting it all together

The next version of Nominatim will support language-specific handling of names,
including for names that do not have the language suffix. To start with, it will
be used to be more selective about which abbreviations are applied to a name.
In the future we shall look at applying more classic means of language-sensitive
text normalization techniques.
