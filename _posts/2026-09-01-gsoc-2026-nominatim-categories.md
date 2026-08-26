---
layout: post
title: "GSoC 2026: Giving Nominatim a Category Model"
author: Agasta
---

Oh hey! I'm Agasta... I believe you don't know me, so here's my [intro](https://www.openstreetmap.org/user/Agasta07/diary/408790). This summer I was [selected for GSoC](https://wiki.openstreetmap.org/wiki/Google_Summer_of_Code/2026/Accepted_projects) to work on Nominatim with Sarah and Marc.

For anyone unfamiliar: Nominatim is a geocoder that uses OpenStreetMap data to turn place names and addresses into coordinates. Every place in OSM gets tagged with a key/value pair like `amenity=restaurant` or `tourism=hotel`, which Nominatim stores internally as a `class`/`type` combination. That's the system this project changed.

At the start of GSoC, I wanted to give Nominatim a proper category model. By the end of the coding period, I had changed the import pipeline, the PostgreSQL schema, ranking and trigger logic, the search indexes, the migration path, the API, the SQLite adaptor, and quite a few tests.

That sounds nicely planned when written as one sentence. It did not feel that way while I was doing it.

The project started with a fairly clear problem: Nominatim only allowed one `class`/`type` pair per place. That works for a simple object, but it becomes awkward as soon as one object has multiple main tags. A hotel that also contains a restaurant could become two database rows. Administrative boundaries needed special handling through `admin_level`, and there was no useful way to express hierarchical filters such as "anything under `osm.amenity`".

![One object, more than one category](/img/2608-gsoc-intro.png)

My [midterm post](https://www.openstreetmap.org/user/Agasta07/diary/409035) covered the first half of the implementation. This is the final part of that story. If you don't know Nominatim's database schema, that is fine. I will explain the pieces that matter as they come up.

## the project became a data-model change

The original model looked roughly like this:

![Original class/type model](/img/2608-gsoc-old-model.png)

The category model keeps both identities on one row:

![Category model with ltree paths](/img/2608-gsoc-category-model.png)

The existing `class` and `type` columns did not disappear. They are still useful in API responses and for compatibility with existing consumers. Their role changed: categories became the source for filtering and classification logic, while `class` and `type` remained the familiar presentation fields.

The main storage choice was [PostgreSQL's `ltree` extension](https://www.postgresql.org/docs/current/ltree.html). A category is a dot-separated path, so PostgreSQL can understand that `osm.amenity.restaurant` is below `osm.amenity` without making the importer store every prefix explicitly.

```sql
-- Match all descendants of osm.amenity
WHERE categories <@ 'osm.amenity'::ltree

-- Match one exact category
WHERE 'osm.amenity.restaurant'::ltree = ANY(categories)
```

I had considered a `TEXT[]` column with prefix expansion and a GIN index. That approach would have avoided the extension dependency, but it would also have moved hierarchy handling into application code and stored more data. After testing the alternatives on real Nominatim data, `ltree[]` was the better fit.

There was one compatibility detail that mattered immediately. Nominatim supports PostgreSQL versions where `ltree` labels cannot contain all the characters that can appear in OSM tag values. The importer therefore normalizes labels, replacing hyphens with `_` and falling back to `yes` for values that cannot be represented. The original value remains available through the normal class/type and extratags data.

That means a value such as:

```text
shop=car-repair
```

becomes a category that can be stored safely across the supported PostgreSQL versions:

```text
osm.shop.car_repair
```

## PR #4106: generating one row instead of merging rows later

The first major implementation landed in [PR #4106](https://github.com/osm-search/Nominatim/pull/4106). It added the `categories ltree[]` column to `place` and `placex`, generated categories in the Lua import code, updated the SQL ranking and trigger functions, and added migration support.

One of the most useful review comments came from Sarah. My first implementation still produced one row per main tag and merged the rows afterwards. That model could work, but it created several rows only to immediately collapse them again.

So I moved the merge into `process_tags()`. The importer now collects the categories first and writes one row:

```lua
local categories = {}

for _, tag in ipairs(main_tags) do
    table.insert(categories, get_category(tag.key, tag.value))
end

insert {
    class = selected_class,
    type = selected_type,
    categories = categories,
    extratags = extratags,
}
```

The `class`/`type` winner is selected deterministically. The current rule is deliberately boring: use a stable ordering so that the same set of tags always produces the same legacy value. That stability matters during updates. If the winner changed randomly, an update could look like a different place to downstream logic even when the OSM tags had not changed.

Ranking was a bigger part of this PR than I expected. Nominatim calculates `search_rank` and `address_rank` from the place classification. Once one row can carry several categories, ranking has to inspect all of them and choose the best applicable result. The SQL functions that used to check conditions such as this:

```sql
class = 'boundary' AND type = 'administrative'
```

now use category paths instead:

```sql
categories <@ 'osm.boundary.administrative'::ltree
```

The same idea had to be applied to trigger code and the indexer. Yk I realized changing a db column in a mature system is rarely a local schema task. Every place that quietly depended on the old representation has to be found.

![Cross-cutting category data flow](/img/2608-gsoc-blast-radius.png)

## migrating a planet database without starting over

Fresh imports were straightforward once the schema and Lua code were in place. Existing installations were harder because `placex` is large enough that "just backfill everything" is a real operational decision.

The migration initially used lazy backfilling. When an existing row was touched, its category could be derived from the old `class` and `type` values. A smaller proactive backfill was still needed for places used as linking targets, especially higher-level address objects.

I tested the migration several times on a planet database. The first version created indexes before the bulk update and took about 63 minutes for 22,221,508 rows. Disabling the update trigger during the backfill and creating the indexes afterwards reduced that to about 47 minutes.

The temporary-table experiment was worse:

```text
indexes first, triggers enabled       ~63 min
backfill first, indexes afterwards   ~47 min
temporary table approach              1 h 40 min
```

PostgreSQL's plan for the temporary-table insert was poor, so the more complicated approach gave us a slower migration. The final process was simpler:

```text
1. Add the column
2. Disable the relevant trigger
3. Backfill categories
4. Build the indexes
5. Re-enable the trigger
6. ANALYZE the affected tables
```

The final production-style migration took about 42 minutes on my planet database. The exact time depends on the machine, storage, and the state of the database, but the important result was that an operator did not need to wait three days for a complete reimport just to get the new column.

![Migration timing comparison](/img/2608-gsoc-migration.png)

## testing the first half, and one testing mistake

The [geocoder tester](https://github.com/geocoders/geocoder-tester) became the main way to check whether the category changes affected ordinary search. On a full planet database, the corrected comparison was:

```text
master       7919 failed, 11113 passed, 3264 skipped
PR #4146     7919 failed, 11113 passed, 3264 skipped
```

The first run made the PR branch look roughly twice as fast, but that was a cache artifact. When I changed the order and ran the tests repeatedly, whichever branch ran first was slow and the later runs settled around 15 to 16 minutes. The failure counts were the more important signal, and they were identical after the database was correctly indexed. For the larger tests, Marc gave me access to a server with a planet database and the extra postcode and ranking files. That setup used PostgreSQL 18 instead of PostgreSQL 17, so its absolute failure count was not directly comparable to mine.

Before that correction, I had blamed the category migration for a large group of airport regressions. The real problem was an interruption. In [last PR testing](https://github.com/osm-search/Nominatim/pull/4106#issuecomment-4854681707) I ran `nominatim replication --catch-up`, which left about 4.5 million rows at `indexed_status = 2`. Those places were not searchable because indexing had stopped part-way through.

That was my own testing mistake. I had changed the database state, failed to check the indexing status, and then started explaining the results as if the code were the only variable. A benchmark is only useful when the database behind it is understood.

![Testing mistake illustration](/img/2608-gsoc-testing.png)

## PR #4146: replacing the old category search path

[PR #4146](https://github.com/osm-search/Nominatim/pull/4146) moved POI and near searches away from the `place_classtype_*` tables and onto the categories column.

Those old tables were materialized per class/type pair. A large installation could have hundreds of them, each with its own centroid index and trigger maintenance. The new query was conceptually much smaller:

```sql
-- Old path
SELECT place_id
FROM place_classtype_amenity_restaurant
WHERE centroid @ box;

-- New path
SELECT place_id
FROM placex
WHERE categories <@ 'osm.amenity.restaurant'::ltree
  AND ST_CoveredBy(centroid, box);
```

The first version of the new path exposed an index problem. The categories index could find every restaurant, but it knew nothing about the requested area. The geometry index knew about the area, but it was very large. PostgreSQL ended up building large bitmaps and combining them.

On a fully backfilled planet, `osm.amenity.restaurant` matched roughly 1.8 million rows. A near search could therefore pay to build a bitmap for almost every restaurant on Earth before applying the spatial filter.

![Index problem illustration](/img/2608-gsoc-index-problem.png)

The first numbers looked bad:

| Configuration                     |     Time |
| --------------------------------- | -------: |
| Old `place_classtype` path        |    ~8 ms |
| Categories + geometry path (warm) |  ~655 ms |
| Categories + geometry path (cold) | ~2617 ms |

The fix was a combined GiST index and a return to centroid-based filtering:

```sql
CREATE INDEX idx_placex_centroid_categories ON placex
USING GIST (
    centroid,
    categories gist__ltree_ops(siglen=8)
);
```

The two changes had to land together. Switching only to `centroid` while keeping the old categories-only index was actually worse. With the combined index, the same tests looked much better:

| Configuration                      |      POI |    Near |
| ---------------------------------- | -------: | ------: |
| Master / place_classtype tables    |  0.69 ms | 22.6 ms |
| Category path, old index           | 106.5 ms |  510 ms |
| Combined centroid/categories index |  1.28 ms |   75 ms |


The new index was still slower than the specialized old tables in some cases, but it replaced 428 tables and about 8.2 GB of separate table/index storage with one general-purpose index. The design also gave us a single place to extend category filtering later.

So, is it faster? The answer depends on the query. The combined index brings the new POI path close to the old specialized tables and makes near searches much better than the first category-only version. The bigger win is that the database no longer needs hundreds of separately maintained tables.

The index discussion changed my understanding of PostgreSQL GiST indexes. I initially explained the column order using an incomplete argument about which columns could be used by a multicolumn index. The real advantages of the chosen order were the measured index size, build time, and the way the centroid queries behaved. I remember we had some crazy testing and discussions over email about this before the change was finalized.

## PR #4163: removing 428 tables

Once searches no longer depended on the old tables, [PR #4163](https://github.com/osm-search/Nominatim/pull/4163) removed the `place_classtype_*` table creation and maintenance code.

That removed more than a database object. It removed the special-phrase importer code that created those tables, trigger paths that maintained them, SQLite export code that copied them, and the `--min` option whose meaning only existed because those tables existed.

This was a satisfying change because the result is easy to explain:

```text
before: one materialized table per class/type combination
after: one categories column and one indexed search path
```

It also made the architecture easier to reason about. A category is now data on the place, not a collection of side tables that happen to represent the same idea.

![Before/after storage architecture](/img/2608-gsoc-remove-tables.png)

## the API was originally a stretch goal

The project proposal treated API filtering as a stretch goal. Since the database work landed early enough, I added `include` and `exclude` to `/search` in [PR #4164](https://github.com/osm-search/Nominatim/pull/4164). This means users can now ask Nominatim for results under a category, or leave out a category, without knowing how the database stores the place.

Examples:

```text
/search?q=restaurant+berlin&include=osm.amenity.restaurant
/search?q=berlin&include=osm.amenity
/search?q=hilton&include=osm.tourism.hotel&include=osm.amenity.restaurant
/search?q=restaurants+in+berlin&exclude=osm.amenity.fast_food
```

The semantics follow Photon's category filters. A comma and a repeated parameter mean different things:

```text
include=a.b,c.d       -> match a.b OR c.d
include=a.b&include=c.d -> match a.b AND c.d

exclude=a.b,c.d       -> exclude when both are present
exclude=a.b&exclude=c.d -> exclude when either is present
```

The last two rules look strange until the boolean logic is written down. They follow from applying De Morgan's law to the exclusion groups, and they are compatible with the behaviour users already see in Photon.

The filter is applied across the search paths that return `placex` rows, rather than silently doing nothing on a normal name search. Sources without categories, such as postcodes, interpolations, TIGER data, and some country fallback tables, cannot satisfy an `include` filter.

The API work also found a bug in the PostgreSQL array result processor. It was returning the raw `'{a,b}'` array literal as a string. Once the new API started reading categories, SQLite export could interpret that string as individual characters.

![Array bug illustration](/img/2608-gsoc-api-array-bug.png)

That was a latent bug in the earlier category work, not something I had planned to fix. It is one reason I now try to test new data paths through every supported backend instead of only testing the path that motivated the change.

The final API tests cover validation, repeated parameters, hierarchy matching, AND/OR semantics, SQLite behaviour, and the POI, near, place, address, and country search paths.

![API request flow](/img/2608-gsoc-api-flow.png)


## documentation is part of the implementation

The last open piece is documentation. [PR #4166](https://github.com/osm-search/Nominatim/pull/4166) updates the migration, API, customization, and developer documentation for the category series. 

I also had to be careful with terminology. Nominatim already uses "category" in a few older contexts, while the new data is stored in `categories`. Now calling the old `class`/`type` values categories made the documentation ambiguous. The final docs use "main tag" for the legacy class/type identity and reserve "categories" for the new paths.



## wrapping up

The technical result is a category system, but the more useful outcome for me was learning how to make a cross-cutting change in a production-oriented open-source codebase. Once these changes land in a release, users will be able to filter search results by category directly through the API. For example:

```text
/search?q=hilton&include=osm.tourism.hotel
/search?q=berlin&include=osm.amenity
/search?q=restaurants+in+berlin&exclude=osm.amenity.fast_food
```

No more second-guessing which "restaurant" result is the one you meant. You ask for hotels, you get hotels.

Getting to that simple API surface meant tracing a single concept across Lua, SQL, PostgreSQL indexes, Python search builders, HTTP adaptors, SQLite conversion, migrations, BDD tests. I also learned that reviews are part of the design process. The most important changes in this project came from questions such as:

- Why create several rows and merge them later?
- Which old class/type checks still need to become category checks?
- How much of the planet needs proactive backfilling?
- What happens when the category index sees 1.8 million restaurants?
- Can SQLite read the same category data?

Some of my first answers were wrong. Yk I remember my mentors telling me at the very first meet that we might get surprises and unplanned turns that always happen when a good plan meets reality. I get it now.

The GSoC period is ending and, according to our scope plan, the project is done. There is no unfinished follow-up task needed to use the feature. The category work can still grow later: current categories are derived from main OSM tags, and a future step could add richer categories such as `cuisine.italian` or `access.wheelchair.yes` once there is a clearer set of real use cases. The foundation now exists for that work without requiring another redesign of the search database.

For me, this summer turned a side-project curiosity about maps into a much better understanding of how a geocoder works under load. I got to work with a planet database, learned a lot about PostgreSQL, ranking, triggers, migrations, and so on. I had a really great time. It was crazy, in the best way.

Thanks to Sarah and Marc for their guidance, patient reviews, and all the unexpected questions that made the implementation better. Thanks to OpenCage for supporting the project with the server I used for the large database tests. And thanks to the OpenStreetMap community and the OpenStreetMap Foundation for making this work possible.

I had a great summer. Thanks for reading :)

If you wanna connect, find me on [X](https://x.com/idkAgasta) or [GitHub](https://github.com/Itz-Agasta).

_Agasta signing out._
