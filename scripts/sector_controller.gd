extends Node2D

@export var sector_type: String = "Ira" # Cambia según el sector ("Ira", "Bondad", etc.)

@onready var boss_spawn_point: Node2D = $MiniBoss_Spawn

func _ready() -> void:
	_spawn_sector_boss()

func _spawn_sector_boss() -> void:
	if not boss_spawn_point:
		return
		
	# Determinar cuál minijefe le corresponde según GameData
	var boss_name: String = ""
	if GameData.active_bosses.has(sector_type):
		boss_name = GameData.active_bosses[sector_type]
	else:
		# Si se eligió Honor, Ira tendrá a Daynan
		if sector_type == "Ira" and GameData.selected_fragment == "Honor":
			boss_name = "Daynan"
		else:
			boss_name = GameData.BOSS_MAPPING.get(sector_type, "")
			
	if boss_name == "":
		return

	print("Instanciando minijefe [", boss_name, "] en el sector de [", sector_type, "]")
	
	# Cargar la escena del minijefe correspondiente
	var boss_path := "res://scenes/entities/bosses/" + boss_name + ".tscn"
	if ResourceLoader.exists(boss_path):
		var boss_scene := load(boss_path) as PackedScene
		var boss_instance := boss_scene.instantiate()
		boss_instance.global_position = boss_spawn_point.global_position
		add_child(boss_instance)
