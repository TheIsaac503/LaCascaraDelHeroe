@tool
extends Node2D

@export var sector_type: String = "Ira"
@export var is_first_sector: bool = false
@export var is_last_sector: bool = false

const ROOM_WIDTH := 560.0
const ROOM_HEIGHT := 360.0
const WALL_THICKNESS := 24.0
const DOOR_GAP := 104.0
const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const NPC_SCRIPT := preload("res://scripts/rescue_npc.gd")

var palette := {
	"Ira": Color("#4b2928"),
	"Bondad": Color("#294638"),
	"Orgullo": Color("#44364e"),
	"Honor": Color("#344457"),
	"Hermandad": Color("#39464a"),
	"Creatividad": Color("#3c3b55"),
	"Amor": Color("#563b50")
}
var accent := {
	"Ira": Color("#e06b43"),
	"Bondad": Color("#7bc47f"),
	"Orgullo": Color("#c4a5e8"),
	"Honor": Color("#d8bd78"),
	"Hermandad": Color("#8ec4c9"),
	"Creatividad": Color("#e2a7f0"),
	"Amor": Color("#e88ba8")
}

func _ready() -> void:
	queue_redraw()
	# En el editor solo dibujamos el mapa; no creamos enemigos ni colisiones dinámicas.
	if Engine.is_editor_hint():
		return
	_build_room_collisions()
	_spawn_room_contents()

func _draw() -> void:
	if Engine.is_editor_hint():
		return
	var floor_color: Color = palette.get(sector_type, Color("#343944"))
	var accent_color: Color = accent.get(sector_type, Color("#d4bd83"))
	for room_index in range(6):
		var center_x := float(room_index) * ROOM_WIDTH
		var room_rect := Rect2(center_x - ROOM_WIDTH / 2.0, -ROOM_HEIGHT / 2.0, ROOM_WIDTH, ROOM_HEIGHT)
		draw_rect(room_rect, floor_color)
		# Losas y marcas de desgaste para que cada habitacion tenga textura.
		for x_step in range(1, 7):
			var x := room_rect.position.x + float(x_step) * ROOM_WIDTH / 7.0
			draw_line(Vector2(x, -ROOM_HEIGHT / 2.0 + 18), Vector2(x, ROOM_HEIGHT / 2.0 - 18), Color(0.08, 0.09, 0.12, 0.22), 2.0)
		for y_step in range(1, 4):
			var y := -ROOM_HEIGHT / 2.0 + float(y_step) * ROOM_HEIGHT / 4.0
			draw_line(Vector2(room_rect.position.x + 18, y), Vector2(room_rect.end.x - 18, y), Color(0.08, 0.09, 0.12, 0.2), 2.0)
		# Bordes de piedra.
		draw_rect(Rect2(room_rect.position.x, room_rect.position.y, ROOM_WIDTH, WALL_THICKNESS), Color("#20232d"))
		draw_rect(Rect2(room_rect.position.x, ROOM_HEIGHT / 2.0 - WALL_THICKNESS, ROOM_WIDTH, WALL_THICKNESS), Color("#20232d"))
		if room_index > 0 or not is_first_sector:
			_draw_side_wall(center_x - ROOM_WIDTH / 2.0, false)
		if room_index < 5 or not is_last_sector:
			_draw_side_wall(center_x + ROOM_WIDTH / 2.0, false)
		# Antorchas/piedras decorativas en esquinas.
		draw_circle(Vector2(center_x - ROOM_WIDTH / 2.0 + 34, -ROOM_HEIGHT / 2.0 + 38), 8, accent_color.darkened(0.25))
		draw_circle(Vector2(center_x + ROOM_WIDTH / 2.0 - 34, -ROOM_HEIGHT / 2.0 + 38), 8, accent_color.darkened(0.25))
		var room_title := "SALA " + str(room_index + 1)
		if room_index == 5:
			room_title = "SALA 6 - JEFE"
		draw_string(ThemeDB.fallback_font, Vector2(center_x - 70, -ROOM_HEIGHT / 2.0 + 55), room_title, HORIZONTAL_ALIGNMENT_CENTER, 140, 14, accent_color)
		if room_index == 2:
			draw_string(ThemeDB.fallback_font, Vector2(center_x - 90, ROOM_HEIGHT / 2.0 - 45), "PRISIONEROS", HORIZONTAL_ALIGNMENT_CENTER, 180, 12, accent_color)
		if room_index == 4:
			draw_string(ThemeDB.fallback_font, Vector2(center_x - 90, ROOM_HEIGHT / 2.0 - 45), "ANTESALA", HORIZONTAL_ALIGNMENT_CENTER, 180, 12, accent_color)

func _draw_side_wall(x: float, unused: bool) -> void:
	var wall_color := Color("#20232d")
	draw_rect(Rect2(x - WALL_THICKNESS / 2.0, -ROOM_HEIGHT / 2.0, WALL_THICKNESS, (ROOM_HEIGHT - DOOR_GAP) / 2.0), wall_color)
	draw_rect(Rect2(x - WALL_THICKNESS / 2.0, DOOR_GAP / 2.0, WALL_THICKNESS, (ROOM_HEIGHT - DOOR_GAP) / 2.0), wall_color)

func _build_room_collisions() -> void:
	for room_index in range(6):
		var center_x := float(room_index) * ROOM_WIDTH
		_add_wall(Vector2(center_x, -ROOM_HEIGHT / 2.0), Vector2(ROOM_WIDTH, WALL_THICKNESS))
		_add_wall(Vector2(center_x, ROOM_HEIGHT / 2.0), Vector2(ROOM_WIDTH, WALL_THICKNESS))
		var left_is_open := room_index > 0 or not is_first_sector
		var right_is_open := room_index < 5 or not is_last_sector
		if left_is_open:
			_add_side_segments(center_x - ROOM_WIDTH / 2.0)
		else:
			_add_wall(Vector2(center_x - ROOM_WIDTH / 2.0, 0), Vector2(WALL_THICKNESS, ROOM_HEIGHT))
		if right_is_open:
			_add_side_segments(center_x + ROOM_WIDTH / 2.0)
		else:
			_add_wall(Vector2(center_x + ROOM_WIDTH / 2.0, 0), Vector2(WALL_THICKNESS, ROOM_HEIGHT))

func _add_side_segments(x: float) -> void:
	var segment_height := (ROOM_HEIGHT - DOOR_GAP) / 2.0
	_add_wall(Vector2(x, -DOOR_GAP / 2.0 - segment_height / 2.0), Vector2(WALL_THICKNESS, segment_height))
	_add_wall(Vector2(x, DOOR_GAP / 2.0 + segment_height / 2.0), Vector2(WALL_THICKNESS, segment_height))

func _add_wall(wall_position: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = wall_position
	body.collision_layer = 1
	body.collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

func _spawn_room_contents() -> void:
	# Las salas 2 a 5 contienen enemigos; la sexta reserva su centro al minijefe.
	var enemy_positions := {
		1: [Vector2(-55, -25)],
		2: [Vector2(-70, 25), Vector2(75, -25)],
		3: [Vector2(-65, -35), Vector2(65, 35)],
		4: [Vector2(-100, 0), Vector2(0, -35), Vector2(100, 20)]
	}
	for room_index in enemy_positions.keys():
		for local_offset in enemy_positions[room_index]:
			var enemy = ENEMY_SCENE.instantiate()
			enemy.position = Vector2(float(room_index) * ROOM_WIDTH, 0) + local_offset
			add_child(enemy)
	var npc := Node2D.new()
	npc.name = "RescueNPC_" + sector_type
	npc.set_script(NPC_SCRIPT)
	npc.position = Vector2(2.0 * ROOM_WIDTH, 15)
	npc.set("npc_name", "Prisionero de " + sector_type)
	add_child(npc)
	_spawn_boss()

func _spawn_boss() -> void:
	var boss_name: String = str(GameData.active_bosses.get(sector_type, ""))
	if boss_name == "" and sector_type == "Ira" and GameData.selected_fragment == "Honor":
		boss_name = "Daynan"
	if boss_name == "":
		boss_name = str(GameData.BOSS_MAPPING.get(sector_type, ""))
	if boss_name == "":
		return
	var boss_path := "res://scenes/entities/bosses/" + boss_name + ".tscn"
	if not ResourceLoader.exists(boss_path):
		push_warning("No se encontro el minijefe: " + boss_path)
		return
	var boss_scene := load(boss_path) as PackedScene
	var boss_instance := boss_scene.instantiate()
	boss_instance.name = "BossRoom6_" + boss_name
	boss_instance.position = Vector2(5.0 * ROOM_WIDTH, 0)
	add_child(boss_instance)
	print("Minijefe ", boss_name, " colocado en la sala 6 del sector ", sector_type)
