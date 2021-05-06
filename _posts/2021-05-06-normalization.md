---
layout: post
title: "The importance of normalization"
author: Sarah Hoffmann (lonvia)
---

Normalization is the process of transforming a text into a form that only
contains the information relevant for search. It is an essential part of the
search process and has a huge influence on the quality of results. Time to
have a closer how it works in Nominatim and how we plan to improve it.

## Defining Normalization

Normalization transforms the text into a form that makes it easier to search
and compare. There are different reasons to do this:

* __Removing unwanted information.__ Some parts of the are simply not relevant
  for the search. Subsequent whitespaces are usually merged, special characters
  like tabulators or line feeds are removed. If a letter is upper case or lower
  case is usually not deemed relevant.

* __Harmonization of notation.__ There are often multiple ways to express the
  same thing. For example, decimal numbers exist in many scripts and mean
  exactly the same. Normalising them to one script (usually Latin), simplifies
  matching of text greatly. Also scripts that use diacritics are usually
  still understandable without these special marks, which is why they tend to
  be used inconsistently. Normalization therefore often removes them.

* __Transliteration to Latin script.__ Unicode has made it possible to write
  queries in any language. But handling the full range of Unicode characters
  would make matching more complicated. Text is therefore usually transliterated
  into an equivalent in Latin script, so that all further algorithms can work
  with simple ASCII code.

Each of these steps takes away a bit of information from the text, so you have
to be careful what you do. To give you an obvious example, let's have a
look at abbreviations.

Abbreviations are frequently used in addresses, much more so than in regular
texts. We abbreviates streets ('st'), states ('AZ', 'CA'), and even brand
names ('McDo'). Abbreviations could be seen as a special form of normalization.
If all abbreviable words in a text are shortened during normalization, then
the problem can simply be ignored afterwards. However, this might be dangerous.
A single abbreviation often is a placeholder for different words. Consider the
famous example of 'St Andrew's St' where 'st' stands once for 'saint' and once
for 'street'. Often the meaning is obvious enough from the context but there
are cases where loosing the original information leads to worse search results.

## Normalization in search

There are two places where normalization is used in a search engine:

* __Normalization of names during import.__ When a new place is imported into
  the database, its names are normalized and only the normalized form is
  saved in the search index.

* __Normalization of the query.__ At query time, the incoming query text is
  first normalized and then compared against the search index.

Here is the tricky part: the two steps have to use exactly the same
normalization (or at least algorithms that are compatible in that they
yield the same normalized form for the same kind of information). This
makes it very hard to change the normalization process in a search software.
If you do this, then you either have to reimport or renormalize your
entire database. Or you have to provide the means that existing installations
still can use their old way of normalizing text.

## Normalization in Nominatim

Nominatim has a rather crude normalization process. First the text is
transliterated into ASCII with a home-made translation table
and then some hard-coded replacements are applied
to provide for simple abbreviation support. All this is implemented in an
extension to PostgreSQL. Doing this was a sensible decision at the time.
Most of the process of importing data is implemented in pl/pgSQL, in
PostgreSQL functions. The query code is written in PHP. Having the normalization
in an SQL function means that both parts of the code are guaranteed to use
the same algorithm. Implementing it as a PostgreSQL C function means that it is
blazingly fast.

The disadvantages of the approach are obvious. First and foremost, the
normalization module is almost impossible to maintain. Fixing an error in the
transliteration means finding the right spot in [an array of 65536 elements](https://github.com/osm-search/Nominatim/blob/3.7.x/module/utfasciitable.h).
This table has been touched exactly 2 times in its 10-year existence.

The other problem is that it is impossible to customize. There are valid
use cases of special search applications that work better with a different set
of abbreviations. Or a region-specific search database might want to use a
transliteration most frequently used in their area. Nominatim should be easier
configurable for cases like this.

## The future

With the recent [refactoring to Nominatim](https://github.com/osm-search/Nominatim/pull/2305),
we have started to untangle the normalisation code from the rest of the code
base. This was a bit tricky because usage of the old PostgreSQL normalisation
module was spread all over the place. There are parts in the Python code
responsible for importing and updating data, in the SQL code that computes
the addresses of a place and in the PHP code that handles the queries. All the
uses have been isolated into a new _tokenizer_ module[^1]. What is more, the
tokenizer now installs all relevant configuration information about
normalization when a database is first imported. This ensures that the
algorithm does not change, even when the software is updated.

With the tokenizer thus nicely configurable, we can now start to experiment
with new ways of normalization that might better suite searching in geographic
databases. One of the first alternative implementations will use
[libICU](https://unicode-org.github.io/icu/userguide/icu/) instead of our
PostgreSQL module. This will give us a more standardized normalization and,
more importantly, will make installation of Nominatim a little bit easier.

[^1]: It is called tokenizer because the module does a bit more than only
      normalize text. It also splits the text into _word tokens_, the true
      unit of text a search engine works with.
