extends Node2D

const ROOM_WIDTH := 750.0
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
	active_fragments.shuffle()
	GameData.sector_positions.clear()
	GameData.starting_sector = ""
	var spawn_pos := Vector2.ZERO
	print("--- GENERANDO MAZMORRA: SECTORES EN ORDEN ALEATORIO ---")
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
		sector_node.add_to_group("active_sectors")
		
		add_child(sector_node)
		var first_room := sector_node.get_node_or_null("Sala_1") as Node2D
		GameData.sector_positions[fragment] = first_room.global_position if first_room != null else sector_node.global_position
		if i == 0:
			GameData.starting_sector = fragment
		spawn_pos.x += ROOM_WIDTH * ROOMS_PER_SECTOR
		print("Sector cargado: ", fragment, " (6 salas)")
	# Isaac aparece en la sala 1 del primer sector de la lista aleatoria.
	var player := get_parent().get_node_or_null("Isaac") as Node2D
	if player != null and GameData.starting_sector != "":
		var start_position: Vector2 = GameData.sector_positions[GameData.starting_sector]
		player.global_position = start_position
		print("Sector inicial aleatorio: ", GameData.starting_sector)
