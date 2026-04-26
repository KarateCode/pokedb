# Pokemon card display functions
# Usage: source pokemon-card.nu
#        pokeCard 25      # Display card for Pokemon with id 25
#        pokePick         # Browse all Pokemon with fzf, then display card

# Calculate type effectiveness multiplier for an attacking type against defender's types
# Returns: 0 (immune), 0.25, 0.5, 1, 2, or 4
def calc-effectiveness [defender_types: list, attacker: record] {
    $defender_types | each { |def_type|
        let dominated_by_attacker = ($attacker.strengths | from json)
        let resists_attacker = ($attacker.weaknesses | from json)
        let immune_to_attacker = ($attacker.immunes | from json)

        if ($def_type in $immune_to_attacker) {
            0.0
        } else if ($def_type in $dominated_by_attacker) {
            2.0
        } else if ($def_type in $resists_attacker) {
            0.5
        } else {
            1.0
        }
    } | math product
}

# Get list of weaknesses for a Pokemon's types, sorted by severity
def get-weaknesses [defender_types: list, all_types: table] {
    $all_types
    | each { |atk|
        let mult = (calc-effectiveness $defender_types $atk)
        { name: $atk.name, multiplier: $mult }
    }
    | where multiplier > 1
    | sort-by multiplier --reverse
}

def pokeCard [id: int, --no-images] {
    let db = "pokemon.db"
    let images_dir = "../pokemon.json/images"

    # Fetch Pokemon from database
    let pokemon = (open $db | get pokemon | where id == $id | first)

    if ($pokemon | is-empty) {
        print $"(ansi red)Pokemon with id ($id) not found!(ansi reset)"
        return
    }

    # Fetch all types for weakness calculation
    let all_types = (sqlite3 -json $db "SELECT * FROM types" | from json)

    # Build padded pokedex number for image filename
    let padded = ($pokemon.pokedexId | fill -a right -c '0' -w 3)
    let image_path = $"($images_dir)/($padded).png"

    # Display the image if it exists
    if not $no_images {
        if ($image_path | path exists) {
            chafa --size=40x20 $image_path
        } else {
            print $"(ansi yellow)No image found for pokedex #($pokemon.pokedexId)(ansi reset)"
        }
    }

    # Colors
    let cyan = (ansi cyan)
    let yellow = (ansi yellow)
    let green = (ansi green)
    let red = (ansi red)
    let white = (ansi white)
    let magenta = (ansi magenta)
    let blue = (ansi blue)
    let reset = (ansi reset)
    let bold = (ansi attr_bold)
    let dimmed = (ansi white_dimmed)

    # Type color map
    let type_colors = {
        Normal: (ansi white),
        Fire: (ansi red),
        Water: (ansi blue),
        Electric: (ansi yellow),
        Grass: (ansi green),
        Ice: (ansi cyan),
        Fighting: (ansi red_bold),
        Poison: (ansi magenta),
        Ground: (ansi yellow),
        Flying: (ansi cyan),
        Psychic: (ansi magenta),
        Bug: (ansi green),
        Rock: (ansi yellow),
        Ghost: (ansi magenta),
        Dragon: (ansi magenta_bold),
        Dark: (ansi white_dimmed),
        Steel: (ansi white),
        Fairy: (ansi magenta)
    }

    # Pokemon's types
    let types = ($pokemon.types | from json)

    # Calculate weaknesses
    let weaknesses = (get-weaknesses $types $all_types)

    # Build type display string
    let type_display = ($types | each { |t|
        let color = ($type_colors | get -o $t | default (ansi white))
        $"($color)($t)($reset)"
    } | str join " / ")

    # Build weakness display lines
    let weakness_lines = ($weaknesses | each { |w|
        let type_color = ($type_colors | get -o $w.name | default (ansi white))
        let mult_text = if $w.multiplier == 4 {
            $"($bold)($red)\(4x\)($reset)"
        } else {
            $"($yellow)\(2x\)($reset)"
        }
        $"    ($type_color)($w.name)($reset) ($mult_text)"
    })

    # Stats with bars - pre-calculate for side-by-side display
    let stats = [
        {name: "HP", value: $pokemon.hp},
        {name: "Attack", value: $pokemon.attack},
        {name: "Defense", value: $pokemon.defense},
        {name: "Sp. Atk", value: $pokemon.spAttack},
        {name: "Sp. Def", value: $pokemon.spDefense},
        {name: "Speed", value: $pokemon.speed}
    ]

    # Target width for left column (visible characters)
    let left_width = 42
    let pad = ("" | fill -c " " -w $left_width)

    let stat_lines = ($stats | each { |stat|
        let name = ($stat.name | fill -a left -w 8)
        let value = ($stat.value | into string | fill -a right -w 3)

        let bar_width = 20
        let filled = (($stat.value / 255) * $bar_width | math round | into int)
        let empty = $bar_width - $filled

        let bar_color = if $stat.value >= 100 {
            $green
        } else if $stat.value >= 60 {
            $yellow
        } else {
            $red
        }

        let filled_bar = (1..$filled | each { "█" } | str join)
        let empty_bar = (1..$empty | each { "░" } | str join)

        # Stat line visible: "  HP      : 100 " (16) + bar (20) = 36 chars, need 6 more
        $"($cyan)  ($name):($reset) ($value) ($bar_color)($filled_bar)($dimmed)($empty_bar)($reset)      "
    })

    let total = $pokemon.hp + $pokemon.attack + $pokemon.defense + $pokemon.spAttack + $pokemon.spDefense + $pokemon.speed

    # Build left column lines - each padded to left_width (42 visible chars)
    let form_text = if $pokemon.form != null { $" \(($pokemon.form)\)" } else { "" }

    # Type line: "  Type:       " (14) + types (variable) - pad the types portion
    let type_label = $"($cyan)  Type:($reset)       "
    let type_content = $type_display
    let types_visible_len = ($types | each { |t| $t | str length } | math sum) + (if ($types | length) > 1 { 3 } else { 0 })
    let type_padding = ("" | fill -c " " -w (28 - $types_visible_len))
    let type_line = $"($type_label)($type_content)($type_padding)"

    # Generation line: "  Generation: X" - pad to 42
    let gen_str = ($pokemon.generation | into string)
    let gen_padding = ("" | fill -c " " -w (28 - ($gen_str | str length)))
    let gen_line = $"($cyan)  Generation:($reset) ($white)($gen_str)($reset)($gen_padding)"

    # Base Stats header: "  --- Base Stats ---" (22 visual) - pad to 42
    let stats_header = $"($bold)($cyan)  --- Base Stats ---($reset)                      "

    # Total line: "     Total: XXX" (12 + len) - pad to 42, so need (30 - len) spaces
    let total_str = ($total | into string)
    let total_padding = ("" | fill -c " " -w (30 - ($total_str | str length)))
    let total_line = $"($cyan)     Total:($reset) ($bold)($total)($reset)($total_padding)"

    let left_col = [
        $type_line
        $gen_line
        $pad
        $stats_header
    ] | append $stat_lines | append [$pad, $total_line]

    # Build right column lines
    let right_col = [$"($bold)($cyan)Weak To:($reset)"] | append $weakness_lines

    # Pad columns to same number of lines
    let left_len = ($left_col | length)
    let right_len = ($right_col | length)
    let max_lines = if $left_len > $right_len { $left_len } else { $right_len }
    let left_extra = $max_lines - $left_len
    let right_extra = $max_lines - $right_len
    let empty_left_line = ("" | fill -c " " -w $left_width)
    let left_padded = if $left_extra > 0 { $left_col | append (1..$left_extra | each { $empty_left_line }) } else { $left_col }
    let right_padded = if $right_extra > 0 { $right_col | append (1..$right_extra | each { "" }) } else { $right_col }

    # Header
    print ""
    print $"($bold)($yellow)═══════════════════════════════════════════════════════════════($reset)"
    print $"($bold)($green) #($pokemon.pokedexId) ($pokemon.name)($form_text)($reset)"
    print $"($bold)($yellow)═══════════════════════════════════════════════════════════════($reset)"

    # Print side-by-side
    for i in 0..<$max_lines {
        let left_line = ($left_padded | get $i)
        let right_line = ($right_padded | get $i)
        print $"($left_line)($dimmed)│($reset)  ($right_line)"
    }

    print $"($bold)($yellow)═══════════════════════════════════════════════════════════════($reset)"
}

# Browse Pokemon with fzf and display selected card
def pokePick [] {
    let db = "pokemon.db"

    # Get all Pokemon, format for fzf display
    let selection = (
        open $db
        | get pokemon
        | each { |p|
            let form_text = if $p.form != null { $" \(($p.form)\)" } else { "" }
            let pokedex_padded = ($p.pokedexId | fill -a right -c ' ' -w 4)
            let gen_text = $"Gen ($p.generation)"
            # Format: "id | #pokedexId | Name (Form) | Gen X"
            $"($p.id)\t#($pokedex_padded)\t($p.name)($form_text)\t($gen_text)"
        }
        | str join "\n"
        | fzf --header="Pick a Pokemon" --ansi --delimiter="\t" --with-nth=2..
    )

    if ($selection | is-empty) {
        return
    }

    # Extract the id (first field before tab)
    let id = ($selection | split row "\t" | first | into int)
    pokeCard $id
}
