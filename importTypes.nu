#!/usr/bin/env nu

# Pokemon Types SQLite Import Script
# Usage: nu importTypes.nu

let db = "pokemon.db"
let types_path = "../pokemon-type-chart/types.json"

print "Dropping existing types table if present..."
sqlite3 $db "DROP TABLE IF EXISTS types"

print "Importing Types..."
open $types_path
| each { |t| {
    name: $t.name,
    immunes: ($t.immunes | to json -r),
    weaknesses: ($t.weaknesses | to json -r),
    strengths: ($t.strengths | to json -r)
}}
| into sqlite $db -t types

let types_count = (sqlite3 $db "SELECT COUNT(*) FROM types")
print $"Imported ($types_count) Types"

print "Done!"
