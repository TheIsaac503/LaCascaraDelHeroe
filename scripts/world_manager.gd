extends Node2D

const ROOM_WIDTH := 560.0
const ROOMS_PER_SECTOR := 6
const SECTOR_SCENES := {
	"Ira": "res://scenes/sectors/Ira_Sector.tscn",
	"Bondad": "res://scenes/sectors/Bondad_Sector.tscn",
	"Orgullo": "res://scenes/sectors/Orgullo_Sector.tscn",
	"Honor": "res://scenes/sectors/Honor_Sector.tscn",
	"Hermandad": "res://scenes/sectors/Hermandad_Sector.tscn",
	"Creatividad": "res://scenes/sectors/Creatividad_Sector.tscn",
	"Amor": "res://scenes/sectors/Amor_Sector.tscn"
}

func _ready() -> void:
	# Dibuja las salas antes que Isaac para no tapar al personaje.
	get_parent().move_child.call_deferred(self, 0)
	_remove_old_test_arena()
	generate_dungeon()
	var soul_label := get_parent().get_node_or_null("HUD/SoulLabel")
	if soul_label is Label:
		soul_label.text = "FRAGMENTO: " + GameData.selected_fragment.to_upper()

func _remove_old_test_arena() -> void:
	# Main.tscn tenia una arena de pruebas; se retira para usar las salas nuevas.
	for child_name in ["Floor", "Walls", "Pillar", "Enemy", "RangedEnemy", "Ground"]:
		var old_node := get_parent().get_node_or_null(child_name)
		if old_node != null:
			old_node.queue_free()

func generate_dungeon() -> void:
	var active_fragments: Array[String] = []
	for fragment in SECTOR_SCENES.keys():
		if fragment != GameData.selected_fragment:
			active_fragments.append(fragment)
	var spawn_pos := Vector2.ZERO
	print("--- GENERANDO MAZMORRA: 6 SALAS POR SECTOR ---")
	print("Fragmento elegido: ", GameData.selected_fragment)
	for i in range(active_fragments.size()):
		var fragment: String = active_fragments[i]
		var scene_path: String = SECTOR_SCENES[fragment]
		if not ResourceLoader.exists(scene_path):
			push_warning("No se encontro el sector: " + scene_path)
			continue
		var sector_scene := load(scene_path) as PackedScene
		var sector_node := sector_scene.instantiate()
		sector_node.position = spawn_pos
		sector_node.set("sector_type", fragment)
		sector_node.set("is_first_sector", i == 0)
		sector_node.set("is_last_sector", i == active_fragments.size() - 1)
		add_child(sector_node)
		spawn_pos.x += ROOM_WIDTH * ROOMS_PER_SECTOR
		print("Sector cargado: ", fragment, " (6 salas)")
