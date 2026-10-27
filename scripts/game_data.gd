extends Node

var selected_fragment: String = "Amor"
var active_bosses: Dictionary = {}
var available_boss_fragments: Array[String] = []
var intro_completed: bool = false
var rescued_npcs: int = 0
var amy_spared := false
var spared_bosses: Array[String] = []
var brotherhood_set_pieces: Array[String] = []

const BOSS_MAPPING := {
    "Ira": "Radius",
    "Bondad": "Acalenia",
    "Orgullo": "Srbos",
    "Honor": "Daynan",
    "Hermandad": "Anclis",
    "Creatividad": "Arquis",
    "Amor": "Amy"
}

func select_player_fragment(fragment_name: String) -> void:
    choose_fragment(fragment_name)

func reset_game() -> void:
    selected_fragment = "Amor"
    active_bosses.clear()
    available_boss_fragments.clear()
    intro_completed = false
    rescued_npcs = 0
    amy_spared = false
    spared_bosses.clear()
    brotherhood_set_pieces.clear()

func choose_fragment(fragment_name: String) -> void:
    selected_fragment = fragment_name
    active_bosses.clear()
    available_boss_fragments.clear()
    for fragment in BOSS_MAPPING.keys():
        if fragment == fragment_name:
            continue
        var boss_name: String = BOSS_MAPPING[fragment]
        if fragment == "Ira" and fragment_name == "Honor":
            boss_name = "Daynan"
        active_bosses[fragment] = boss_name
        available_boss_fragments.append(fragment)
    available_boss_fragments.shuffle()
