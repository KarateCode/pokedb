# Pokemon card display function
# Usage: source pokemon-card.nu; pokeCard 25

def pokeCard [id: int] {
    let db = "pokemon.db"
    let images_dir = "../pokemon.json/images"

    # Fetch Pokemon from database
    let pokemon = (open $db | get pokemon | where id == $id | first)

    if ($pokemon | is-empty) {
        print $"(ansi red)Pokemon with id ($id) not found!(ansi reset)"
        return
    }

    # Build padded pokedex number for image filename
    let padded = ($pokemon.pokedexId | fill -a right -c '0' -w 3)
    let image_path = $"($images_dir)/($padded).png"

    # Display the image if it exists
    if ($image_path | path exists) {
        chafa --size=40x20 $image_path
    } else {
        print $"(ansi yellow)No image found for pokedex #($pokemon.pokedexId)(ansi reset)"
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

    # Header
    print ""
    print $"($bold)($yellow)═══════════════════════════════════════($reset)"
    let form_text = if $pokemon.form != null { $" \(($pokemon.form)\)" } else { "" }
    print $"($bold)($green) #($pokemon.pokedexId) ($pokemon.name)($form_text)($reset)"
    print $"($bold)($yellow)═══════════════════════════════════════($reset)"

    # Types with color coding
    let types = ($pokemon.types | from json)
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

    let type_display = ($types | each { |t|
        let color = ($type_colors | get -o $t | default (ansi white))
        $"($color)($t)($reset)"
    } | str join " / ")

    print $"($cyan)  Type:($reset)       ($type_display)"
    print $"($cyan)  Generation:($reset) ($white)($pokemon.generation)($reset)"

    # Stats section
    print ""
    print $"($bold)($cyan)  ─── Base Stats ───($reset)"

    # Stats with bars
    let stats = [
        {name: "HP", value: $pokemon.hp},
        {name: "Attack", value: $pokemon.attack},
        {name: "Defense", value: $pokemon.defense},
        {name: "Sp. Atk", value: $pokemon.spAttack},
        {name: "Sp. Def", value: $pokemon.spDefense},
        {name: "Speed", value: $pokemon.speed}
    ]

    for stat in $stats {
        let name = ($stat.name | fill -a left -w 8)
        let value = ($stat.value | into string | fill -a right -w 3)

        # Build stat bar
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

        print $"($cyan)  ($name):($reset) ($value) ($bar_color)($filled_bar)($dimmed)($empty_bar)($reset)"
    }

    # Total
    let total = $pokemon.hp + $pokemon.attack + $pokemon.defense + $pokemon.spAttack + $pokemon.spDefense + $pokemon.speed
    print ""
    print $"($cyan)     Total:($reset) ($bold)($total)($reset)"
    print $"($yellow)═══════════════════════════════════════($reset)"
}
