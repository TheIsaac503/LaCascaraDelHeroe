extends Node

var selected_fragment: String = "Amor"
var active_bosses: Dictionary = {}
var available_boss_fragments: Array[String] = []
var intro_completed: bool = false
var rescued_npcs: int = 0
var amy_spared := false
var amy_extra_life_used := false
var final_battle_active := false
var spared_bosses: Array[String] = []
var brotherhood_set_pieces: Array[String] = []
var sector_positions: Dictionary = {}
var starting_sector: String = ""
var cleared_sectors: Array[String] = []
var final_battle_completed: bool = false
var final_entry_stats: Dictionary = {}

# Fragmentos recuperados y dos habilidades equipables.
var owned_fragments: Array[String] = []
var equipped_abilities: Array[String] = ["Ira", "Bondad"]

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
	amy_extra_life_used = false
	final_battle_active = false
	final_battle_completed = false
	final_entry_stats.clear()
	spared_bosses.clear()
	brotherhood_set_pieces.clear()
	sector_positions.clear()
	starting_sector = ""
	cleared_sectors.clear()
	owned_fragments.clear()
	equipped_abilities = [selected_fragment, ""]

func grant_soul_fragment(fragment_name: String) -> void:
	if not owned_fragments.has(fragment_name):
		owned_fragments.append(fragment_name)
		var player := get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.has_method("apply_new_fragment"):
			player.apply_new_fragment(fragment_name)
		print("Fragmento de alma obtenido: ", fragment_name)

func has_fragment(fragment_name: String) -> bool:
	return owned_fragments.has(fragment_name)

func equip_ability(slot: int, fragment_name: String) -> void:
	if slot < 0 or slot > 1 or not has_fragment(fragment_name):
		return
	while equipped_abilities.size() < 2:
		equipped_abilities.append("")
	equipped_abilities[slot] = fragment_name

func mark_sector_cleared(sector_name: String) -> void:
	if not cleared_sectors.has(sector_name):
		cleared_sectors.append(sector_name)

func choose_fragment(fragment_name: String) -> void:
	selected_fragment = fragment_name
	grant_soul_fragment(fragment_name)
	equipped_abilities = [fragment_name, ""]
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


func are_all_sectors_cleared() -> bool:
	if sector_positions.is_empty():
		return false
	for sector_variant in sector_positions.keys():
		if not cleared_sectors.has(str(sector_variant)):
			return false
	return true

func save_final_entry_stats(player: Node) -> void:
	final_entry_stats.clear()
	for property_name in ["health", "max_health", "attack_damage", "speed", "base_attack_cooldown", "pride_bonus_damage"]:
		var value = player.get(property_name)
		if value != null:
			final_entry_stats[property_name] = value
