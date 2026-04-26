#!/usr/bin/env nu

# Pokemon Hisui Region Import Script
# Usage: nu importHisui.nu
# Adds isHisui column to pokemon table and marks Hisui region Pokemon

let db = "pokemon.db"
let hisui_path = "data/hisui.json"

print "Adding isHisui column to pokemon table (if not exists)..."
sqlite3 $db "ALTER TABLE pokemon ADD COLUMN isHisui INTEGER DEFAULT 0" | complete

print "Resetting all isHisui values to 0..."
sqlite3 $db "UPDATE pokemon SET isHisui = 0"

print "Loading Hisui pokedex IDs..."
let hisui_ids = (open $hisui_path)

print $"Marking ($hisui_ids | length) Hisui Pokemon..."
let id_list = ($hisui_ids | each { |id| $id | into string } | str join ",")
sqlite3 $db $"UPDATE pokemon SET isHisui = 1 WHERE pokedexId IN \(($id_list)\)"

let hisui_count = (sqlite3 $db "SELECT COUNT(*) FROM pokemon WHERE isHisui = 1")
print $"Marked ($hisui_count) Pokemon as Hisui region"

print "Done!"
