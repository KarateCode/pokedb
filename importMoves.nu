#!/usr/bin/env nu

# Pokemon Moves SQLite Import Script
# Imports move reference data from Veekun CSV files
# Usage: nu importMoves.nu

let db = "pokemon.db"
let moves_path = "data/veekun_moves.csv"
let names_path = "data/veekun_move_names.csv"
let damage_classes_path = "data/veekun_move_damage_classes.csv"
let types_path = "data/veekun_types.csv"

print "Dropping existing moves table if present..."
sqlite3 $db "DROP TABLE IF EXISTS moves"

# Build lookup tables
print "Loading damage classes..."
let damage_classes = (open $damage_classes_path 
    | select id identifier 
    | rename id name
    | reduce -f {} {|row, acc| $acc | insert ($row.id | into string) $row.name})

print "Loading type names..."
let type_names = (open $types_path 
    | where id < 10000  # Exclude unknown/shadow types
    | select id identifier 
    | reduce -f {} {|row, acc| $acc | insert ($row.id | into string) $row.identifier})

print "Loading English move names..."
let english_names = (open $names_path 
    | where local_language_id == 9  # English
    | select move_id name
    | reduce -f {} {|row, acc| $acc | insert ($row.move_id | into string) $row.name})

print "Importing Moves..."
let moves = (open $moves_path
    | each { |m|
        let move_id = ($m.id | into string)
        let type_id = ($m.type_id | into string)
        let damage_class_id = ($m.damage_class_id | into string)
        {
            id: $m.id,
            identifier: $m.identifier,
            name: ($english_names | get -o $move_id | default $m.identifier),
            type: ($type_names | get -o $type_id | default "normal"),
            power: (if ($m.power | is-empty) { null } else { $m.power }),
            pp: $m.pp,
            accuracy: (if ($m.accuracy | is-empty) { null } else { $m.accuracy }),
            priority: $m.priority,
            damage_class: ($damage_classes | get -o $damage_class_id | default "status"),
            generation_id: $m.generation_id
        }
    })

$moves | into sqlite $db -t moves

let moves_count = (sqlite3 $db "SELECT COUNT(*) FROM moves")
print $"Imported ($moves_count) Moves"

# Show sample
print "\nSample moves:"
sqlite3 $db "SELECT id, name, type, power, pp, accuracy, damage_class FROM moves LIMIT 10" --header --separator "|" | from csv --separator "|" | table

print "Done!"
