---
layout: tutorial
title: "Customizing Geometries"
author: Alfonso Martínez (alfmarcua)
tags: import lua
---

This tutorial will guide you through the process of customizing geometries in
Nominatim. By customizing geometries, a more refined shape can be achieved for
geographical elements, resulting in more precise and tailored search outcomes
for specific use cases. The ultimate goal is to **replace default OSM geometries
with customized shapes** and to ensure that these custom geometries **remain
intact during data updates** even when data changes come in from OSM.

This requirement is derived from a project under EUROSTAT aimed at developing
[GISCO](https://ec.europa.eu/eurostat/web/gisco) map services to overcome
political issues related to several geometries.

## Prerequisites

Before beginning, ensure that Nominatim is set up and operational on your
system. Comprehensive installation instructions can be found on the [Nominatim
website](https://nominatim.org/release-docs/develop/admin/Installation/). Also,
make sure you have access to the PostgreSQL database that Nominatim is used for
storing OpenStreetMap data.

It is also needed a library for lua scripts to interact with the database. For
that it may be installed with the following command:

```shell
apt install lua-sql-postgres
```

## Steps

### 1. Import OSM Data

With the lua script in place import OpenStreetMap (OSM) data into your Nominatim
database. If not done already, consult the [Nominatim
documentation](https://nominatim.org/release-docs/develop/admin/Import/) for
precise instructions.

### 2. Run SQL for Geometry Modifications and Change OSM_ID to Negative

Proceed to execute SQL queries to modify the geometries of specific elements.
Utilize your preferred SQL client to connect to your Nominatim database.

For example, adjusting geometries can be achieved with SQL statements like:

```sql
UPDATE placex
SET geometry = ST_Simplify(geometry, 0.001), osm_id = -osm_id
WHERE 
  osm_id > 0
  AND boundary = 'administrative'
  AND admin_level = '4' 
  AND osm_type = 'R';
```

In this example, the geometries of relations of administrative boundaries have
been simplified.

It is important that, to discern modified elements from the original data, the
`osm_id` must be set to negative values. The **negative IDs mark all objects
that are changed**, so that they can be later be blocked from being updated.
This practice ensures clear differentiation between the original and customized
elements.

Adapt the `WHERE` clause to correspond to your element selection criteria.
Notice that multiple SQL can be run and for that, all `WHERE` clauses must
contain `osm_id > 0` constrain.

### 3. Lua Script for Blocking Elements

A custom Lua script in append mode will be developed to block elements with
negative `osm_id` values. Since it will affect just in append mode it can be
placed before or after the initial import of the database. For more information,
consult the documentation for setting a [customize
style](https://nominatim.org/release-docs/develop/customize/Import-Styles/).

All negative `osm_id` values shall be retrieved from the database using
`luasql.postgres` and then all negatives `osm_id` will be blocked only in append
mode using `flex.process_tags`.

```lua
-- Import original process tags function from flex-base.lua
local flex = require("flex-base")
local original_process_tags = flex.process_tags

-- Open a database connection to the database.
local driver = require "luasql.postgres"
local env = assert (driver.postgres())
local con = assert (env:connect(""))

-- Get all blocked items, which will not be processed 
function get_blocked_ids()
  -- This is only required for update
  if osm2pgsql.mode == 'append' then
    -- Get all blocked IDs from the database.
    sql = [[ SELECT osm_id FROM placex
             WHERE osm_type = 'R' and osm_id < 0
          ]]
    cur = assert(con:execute(sql))
    blocked = {}
    row = cur:fetch ({})
    while row do
      -- Save the blocked ID as positive
      blocked[-row[1]] = 1
      row = cur:fetch ({})
    end
    return blocked
  end
end

local blocked = get_blocked_ids()

function flex.process_tags(o)   
  -- Ignore bloked elements
  if osm2pgsql.mode == 'append'
    and o.object.type == 'relation'
    and (blocked[(o.object.id)] == 1)
  then
      print("BLOCKED object.id --> " .. o.object.id)
      return
  end

  --Now execute the original processing function.
  original_process_tags(o)
end
```
