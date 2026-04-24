# PokeDb

A SQLite-based Pokemon database project.

## Setup

### Import the data (requires nushell)

```nu
nu importCsv.nu
```

This will:
- Create `pokemon.db` from scratch
- Import all 1215 Pokemon (including alternate forms) from `Pokemon.csv`
- Create indexes for fast lookups

### Alternative: manual schema creation

```bash
# zsh
sqlite3 pokemon.db < schema.sql

# nushell
sqlite3 pokemon.db ".read schema.sql"
```

## Schema

### pokemon

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Auto-incrementing primary key |
| pokedexId | INTEGER | National Pokedex number |
| name | TEXT | English name |
| form | TEXT | Form variant (NULL for base form, e.g., "Mega", "Alolan") |
| types | TEXT | JSON array of types: `["Grass","Poison"]` |
| hp | INTEGER | Base HP stat |
| attack | INTEGER | Base Attack stat |
| defense | INTEGER | Base Defense stat |
| spAttack | INTEGER | Base Special Attack stat |
| spDefense | INTEGER | Base Special Defense stat |
| speed | INTEGER | Base Speed stat |
| generation | INTEGER | Generation introduced (1-9) |

## Example queries

```sql
-- Find all Fire-type Pokemon
SELECT name, types FROM pokemon
WHERE types LIKE '%Fire%';

-- Find all Pokemon with a specific type using JSON
SELECT name, types FROM pokemon, json_each(pokemon.types)
WHERE json_each.value = 'Poison';

-- Top 10 Pokemon by Speed
SELECT name, speed FROM pokemon
ORDER BY speed DESC LIMIT 10;

-- All Mega evolutions
SELECT pokedexId, name, form, types FROM pokemon
WHERE form LIKE 'Mega%';

-- All Gen 9 Pokemon (base forms only)
SELECT pokedexId, name, types FROM pokemon
WHERE generation = 9 AND form IS NULL;

-- Count Pokemon by generation
SELECT generation, COUNT(*) as count FROM pokemon
WHERE form IS NULL
GROUP BY generation;
```

## Legacy scripts

- `importJson.nu` - Original import script for the older JSON data source (809 Pokemon)
