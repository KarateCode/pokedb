#!/usr/bin/env nu

# Pokemon SQLite Database Import Script (from CSV)
# Usage: nu importCsv.nu

let db = "pokemon.db"
let csv_path = "../pokemonData/Pokemon.csv"

# Remove existing database and create fresh with schema
rm -f $db
print "Creating database schema..."
sqlite3 $db ".read schema.sql"

print "Importing Pokemon from CSV..."
open $csv_path
| each { |p|
    # Build types array, filtering out empty Type2
    let types = (
        [$p.Type1 $p.Type2]
        | where { |t| $t != " " and $t != "" }
        | to json -r
    )
    # Convert Form: space or empty string becomes null
    let form = if ($p.Form | str trim) == "" { null } else { $p.Form | str trim }
    {
        pokedexId: $p.ID,
        name: $p.Name,
        form: $form,
        types: $types,
        hp: $p.HP,
        attack: $p.Attack,
        defense: $p.Defense,
        spAttack: ($p."Sp. Atk"),
        spDefense: ($p."Sp. Def"),
        speed: $p.Speed,
        generation: $p.Generation
    }
}
| into sqlite $db -t pokemon

let pokemon_count = (sqlite3 $db "SELECT COUNT(*) FROM pokemon")
print $"Imported ($pokemon_count) Pokemon"

print "Done!"
