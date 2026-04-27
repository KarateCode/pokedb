#!/usr/bin/env nu

# Pokemon Moves Junction Table Import Script
# Imports pokemon-to-move relationships from Veekun CSV
# Usage: nu importPokemonMoves.nu

let db = "pokemon.db"
let pokemon_moves_path = "data/veekun_pokemon_moves.csv"
let methods_path = "data/veekun_pokemon_move_methods.csv"

print "Dropping existing pokemon_moves table if present..."
sqlite3 $db "DROP TABLE IF EXISTS pokemon_moves"

# Build method lookup
print "Loading move methods..."
let methods = (open $methods_path
    | reduce -f {} {|row, acc| $acc | insert ($row.id | into string) $row.identifier})

print $"Loading pokemon moves from ($pokemon_moves_path)..."
print "(This may take a moment - 500K+ rows)"

let pokemon_moves = (open $pokemon_moves_path
    | each { |pm|
        let method_id = ($pm.pokemon_move_method_id | into string)
        {
            pokemon_id: $pm.pokemon_id,
            move_id: $pm.move_id,
            version_group_id: $pm.version_group_id,
            method_id: $pm.pokemon_move_method_id,
            method: ($methods | get -o $method_id | default "unknown"),
            level: (if ($pm.level | is-empty) or ($pm.level == 0) { null } else { $pm.level })
        }
    })

print $"Inserting ($pokemon_moves | length) rows into database..."
$pokemon_moves | into sqlite $db -t pokemon_moves

print "Creating indexes for fast lookups..."
sqlite3 $db "CREATE INDEX IF NOT EXISTS idx_pokemon_moves_pokemon_id ON pokemon_moves(pokemon_id)"
sqlite3 $db "CREATE INDEX IF NOT EXISTS idx_pokemon_moves_move_id ON pokemon_moves(move_id)"
sqlite3 $db "CREATE INDEX IF NOT EXISTS idx_pokemon_moves_method ON pokemon_moves(method)"

let count = (sqlite3 $db "SELECT COUNT(*) FROM pokemon_moves")
print $"Imported ($count) pokemon move relationships"

# Show sample - Bulbasaur's level-up moves
print "\nSample: Bulbasaur's level-up moves (latest version group):"
sqlite3 $db "
    SELECT pm.level, m.name, m.type, m.power, m.damage_class
    FROM pokemon_moves pm
    JOIN moves m ON pm.move_id = m.id
    WHERE pm.pokemon_id = 1
      AND pm.method = 'level-up'
      AND pm.version_group_id = (SELECT MAX(version_group_id) FROM pokemon_moves WHERE pokemon_id = 1 AND method = 'level-up')
    ORDER BY pm.level, m.name
" -header -column

print "\nDone!"
