-- Pokemon SQLite Database Schema
-- Run with: sqlite3 pokemon.db ".read schema.sql"

CREATE TABLE IF NOT EXISTS pokemon (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pokedexId INTEGER NOT NULL,
    name TEXT NOT NULL,
    form TEXT,                        -- NULL for base form, "Mega", "Alolan", etc.
    types TEXT NOT NULL,              -- JSON array: '["Grass","Poison"]' or '["Fire"]'
    hp INTEGER NOT NULL,
    attack INTEGER NOT NULL,
    defense INTEGER NOT NULL,
    spAttack INTEGER NOT NULL,
    spDefense INTEGER NOT NULL,
    speed INTEGER NOT NULL,
    generation INTEGER NOT NULL,
    isHisui INTEGER DEFAULT 0         -- 1 if Pokemon is in Hisui region (Legends Arceus)
);

CREATE INDEX IF NOT EXISTS idx_pokemon_pokedexId ON pokemon(pokedexId);
CREATE INDEX IF NOT EXISTS idx_pokemon_name ON pokemon(name);
CREATE INDEX IF NOT EXISTS idx_pokemon_generation ON pokemon(generation);
