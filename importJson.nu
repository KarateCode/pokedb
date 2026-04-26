#!/usr/bin/env nu

# Pokemon SQLite Database Import Script
# Usage: nu import.nu

let db = "pokemon.db"
let pokedex_path = "data/pokedex.json"
let moves_path = "data/moves.json"

# Remove existing database to start fresh
rm -f $db

print "Importing Pokemon..."
open $pokedex_path
| each { |p| {
    id: $p.id,
    name_english: $p.name.english,
    name_japanese: $p.name.japanese,
    name_chinese: $p.name.chinese,
    name_french: $p.name.french,
    types: ($p.type | to json -r),
    hp: $p.base.HP,
    attack: $p.base.Attack,
    defense: $p.base.Defense,
    sp_attack: $p.base."Sp. Attack",
    sp_defense: $p.base."Sp. Defense",
    speed: $p.base.Speed
}}
| into sqlite $db -t pokemon

let pokemon_count = (open $db | get pokemon | length)
print $"Imported ($pokemon_count) Pokemon"

print "Importing Moves..."
let categories = { "物理": "Physical", "特殊": "Special", "变化": "Status" }
open $moves_path
| each { |m| {
    id: $m.id,
    name_english: $m.ename,
    name_japanese: $m.jname,
    name_chinese: $m.cname,
    type: $m.type,
    category: ($categories | get $m.category),
    power: $m.power,
    accuracy: $m.accuracy,
    pp: $m.pp,
    tm_number: ($m.tm? | default null)
}}
| into sqlite $db -t moves

let moves_count = (open $db | get moves | length)
print $"Imported ($moves_count) Moves"

print "Creating indexes..."
sqlite3 $db "CREATE INDEX idx_pokemon_name ON pokemon(name_english)"
sqlite3 $db "CREATE INDEX idx_moves_name ON moves(name_english)"
sqlite3 $db "CREATE INDEX idx_moves_type ON moves(type)"

print "Done!"
