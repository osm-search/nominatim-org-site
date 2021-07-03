---
layout: post
title: "Abbreviations"
author: Sarah Hoffmann (lonvia)
---

The [blog post on normalization]({% post_url 2021-05-06-normalization %})
mentioned briefly the importance of handling abbreviations in geocoding.
This post looks at abbreviations in more detail.

Addresses and geographic names are riddled with abbreviations. Street names
have many prefixes and suffixes that are so frequently used that we shorten
them almost without realising it. "street" becomes "st", "road" becomes "rd"
or "saint" shortens to "st". Technically speaking, an abbreviation is nothing
more than a spelling variant. It would be possible to handle them like any
spelling error and just fuzzily match full and abbreviated form. But by handling
them explicitly, we can make sure to prefer differences in the name due to
widely-used spelling variants over accidental spelling errors.

## Abbreviations and search

A search database usually should be able to handle abbreviations when they
appear in the text to be searched and when they appear in the search query. We know that in
OpenStreetMap the convention is to always use the unabbreviated name and the
majority of data follows that rule. This simplifies things a bit
because it is always easier to go from the longer unabbreviated form to the
shorter abbreviation. Once abbreviated, terms become ambiguous and require
some amount of guessing to go back to the original form.

There are different strategies how variants like abbreviations can be handled in
search:

1. Normalize the database and all search queries to one common variant.
2. Create all possible variants at indexing time and save them in the database.
3. Create all possible variants at search time and look them all up in the database.
4. Create some variants in the database, create some at search time.

The first variant is what Nominatim has been doing so far. It has shortened all
terms with abbreviations to the shortest possible version once when importing
the name, and then it applied the same shortening algorithms to the query. Now
query and database can be matched, no matter if any term was abbreviated or not.

The resulting algorithm is simple but potentially looses vital information.
For example, Nominatim knows about the abbreviation from the preposition
"in" to "i" but also about the variant spelling of the number "1" as "I".
To consolidate both variants (after converting all to lower case)
"in" and "i" are both converted to "1". This can
lead to very confusing results. If somebody is searching for a place in India
by using the country code "IN", they might get results that have the number "1"
in the name but are not in India.

Another use-case where the conversion to a common variant is used is word
decomposition. In languages like German that tend to lump nouns together to
form compound nouns, you also find that there is some disagreement for proper
nouns how to write them. "Wienerplatz" and "Wiener Platz" are both used even if
one form may be more correct than the other. Decomposing the compound words
in the database and query is the common approach here. However, this causes
some problems when used with abbreviations. The
[OSM abbreviation list](https://wiki.openstreetmap.org/wiki/Name_finder:Abbreviations#Deutsch_-_German) lists "bach" as a suffix that should be
separated but also as a suffix to be abbreviated to "b". Strictly speaking,
the normalization to the common form would mean that every word ending in a "b"
would need to be split before the final "b". That is, of course, not helpful.

The second and third approach keep all information and work equally well in
terms of result. However, saving all variants in the database can significantly
increase its size. Exploding variants at search time means that searching
becomes more complex and thus takes longer. So when working with multiple
variants, it makes sense to use a mixture of the two approaches:
create the most frequent variants at search time and others during
database creation.

### Nominatim's new abbreviation handling

With the next version Nomination will switch to an approach that handles
variants completely in the database. This is possible because of the special
way how the search indexes are built. When creating the database, first creates
a list of all searchable names, the `word` table. The search index proper,
which lists all the places, then only indirectly refers to the list of names.
That means that variants can be saved in the relatively small word
table without increasing the size of any of the other indexes. So we get the
advantages of keeping information on unabbreviated terms without paying too
much in terms of disk space.

Next to avoiding ambiguity in abbreviated terms, there is another reason to
handle abbreviations entirely while building up the database: at this point
we have a lot more information about the names than at query time. We know
which kind of place the name belongs to (e.g. a street, a shop, a country),
we know which country it is in and we can make a fairly good guess about the
language. All this additional information helps to make better guesses, which
abbreviations may be appropriate and which are not. For example, in Finnish
"road" simply means "tie". Finnish is a language that combines compounds, so
any word ending in "tie" must have a variant where "tie" is separated from
the word stem. This becomes a problem when applied to a global database because
many French words (e.g. partie, sortie) match here as well. A lot of "wrong"
variants are produced.

The most important improvement, however, in the new abbreviation handling
is that it is finally fully configurable. Even if not yet implemented, it is
technically possible with the new system to even change the list of
abbreviations in an existing database. This gives you a lot more flexibility
to suggest suitable abbreviations for your country in the future and
improve Nominatim for your language.
