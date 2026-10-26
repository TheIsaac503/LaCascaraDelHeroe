extends Node2D

const SECTOR_SCENES := {
	"Ira": "res://scenes/sectors/Ira_Sector.tscn",
	"Bondad": "res://scenes/sectors/Bondad_Sector.tscn",
	"Orgullo": "res://scenes/sectors/Orgullo_Sector.tscn",
	"Honor": "res://scenes/sectors/Honor_Sector.tscn",
	"Hermandad": "res://scenes/sectors/Hermandad_Sector.tscn",
	"Creatividad": "res://scenes/sectors/Creatividad_Sector.tscn",
	"Amor": "res://scenes/sectors/Amor_Sector.tscn"
}

@export var sector_offset := Vector2(700, 0)

func _ready() -> void:
	generate_dungeon()

func generate_dungeon() -> void:
	var chosen := GameData.selected_fragment
	print("--- GENERANDO MAZMORRA ---")
	print("Fragmento elegido por Isaac: ", chosen)
	
	var spawn_pos := Vector2.ZERO
	
	for fragment in SECTOR_SCENES.keys():
		# Excluir el sector y minijefe correspondiente al alma elegida
		if fragment == chosen:
			print("Sector EXCLUIDO de la partida: ", fragment)
			continue
			
		var scene_path: String = SECTOR_SCENES[fragment]
		if ResourceLoader.exists(scene_path):
			var sector_scene := load(scene_path) as PackedScene
			var sector_node := sector_scene.instantiate()
			sector_node.global_position = spawn_pos
			add_child(sector_node)
			
			spawn_pos += sector_offset
			print("Sector cargado: ", fragment, " en posicion: ", sector_node.global_position)
