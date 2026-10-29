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
const PORTAL_SCRIPT := preload("res://scripts/teleport_portal.gd")

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
	# El suelo y la decoracion los dibuja cada nodo Sala_1...Sala_6.
	# Asi se respeta la distribucion manual que se ve en el editor 2D.
	pass

func _build_room_collisions() -> void:
	for room in _get_room_nodes():
		var left_open := bool(room.get("show_left_door"))
		var right_open := bool(room.get("show_right_door"))
		var top_open := bool(room.get("show_top_door"))
		var bottom_open := bool(room.get("show_bottom_door"))
		_add_vertical_room_wall(room, -ROOM_WIDTH / 2.0 + WALL_THICKNESS / 2.0, left_open)
		_add_vertical_room_wall(room, ROOM_WIDTH / 2.0 - WALL_THICKNESS / 2.0, right_open)
		_add_horizontal_room_wall(room, -ROOM_HEIGHT / 2.0 + WALL_THICKNESS / 2.0, top_open)
		_add_horizontal_room_wall(room, ROOM_HEIGHT / 2.0 - WALL_THICKNESS / 2.0, bottom_open)

func _get_room_nodes() -> Array[Node2D]:
	var rooms: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and child.name.begins_with("Sala_"):
			rooms.append(child as Node2D)
	rooms.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return int(str(a.name).trim_prefix("Sala_")) < int(str(b.name).trim_prefix("Sala_"))
	)
	return rooms

func _add_vertical_room_wall(room: Node2D, x: float, door_open: bool) -> void:
	if door_open:
		var segment_height := (ROOM_HEIGHT - DOOR_GAP) / 2.0
		_add_wall_to_room(room, Vector2(x, -ROOM_HEIGHT / 2.0 + segment_height / 2.0), Vector2(WALL_THICKNESS, segment_height))
		_add_wall_to_room(room, Vector2(x, DOOR_GAP / 2.0 + segment_height / 2.0), Vector2(WALL_THICKNESS, segment_height))
	else:
		_add_wall_to_room(room, Vector2(x, 0), Vector2(WALL_THICKNESS, ROOM_HEIGHT))

func _add_horizontal_room_wall(room: Node2D, y: float, door_open: bool) -> void:
	if door_open:
		var segment_width := (ROOM_WIDTH - DOOR_GAP) / 2.0
		_add_wall_to_room(room, Vector2(-ROOM_WIDTH / 2.0 + segment_width / 2.0, y), Vector2(segment_width, WALL_THICKNESS))
		_add_wall_to_room(room, Vector2(DOOR_GAP / 2.0 + segment_width / 2.0, y), Vector2(segment_width, WALL_THICKNESS))
	else:
		_add_wall_to_room(room, Vector2(0, y), Vector2(ROOM_WIDTH, WALL_THICKNESS))

func _add_wall_to_room(room: Node2D, wall_position: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = wall_position
	body.collision_layer = 1
	body.collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	shape_node.shape = shape
	body.add_child(shape_node)
	room.add_child(body)

func _spawn_room_contents() -> void:
	var rooms := _get_room_nodes()
	if rooms.size() < 6:
		push_warning("El sector " + sector_type + " no tiene sus seis nodos Sala_1 a Sala_6.")
		return
	# Los enemigos se crean como hijos de su sala: no pueden perseguir a Isaac a otra.
	var enemy_positions := {
		2: [Vector2(-55, -25)],
		3: [Vector2(-70, 25), Vector2(75, -25)],
		4: [Vector2(-65, -35), Vector2(65, 35)],
		5: [Vector2(-100, 0), Vector2(0, -35), Vector2(100, 20)]
	}
	for room_number in enemy_positions.keys():
		var room := get_node_or_null("Sala_" + str(room_number)) as Node2D
		if room == null:
			continue
		for local_offset in enemy_positions[room_number]:
			var enemy := ENEMY_SCENE.instantiate()
			enemy.position = local_offset
			enemy.set("confined_to_room", true)
			var enemy_extents := Vector2(ROOM_WIDTH / 2.0 - 42.0, ROOM_HEIGHT / 2.0 - 42.0)
			var room_angle := absf(wrapf(room.global_rotation, -PI, PI))
			if room_angle > PI / 4.0 and room_angle < 3.0 * PI / 4.0:
				enemy_extents = Vector2(enemy_extents.y, enemy_extents.x)
			enemy.set("room_half_extents", enemy_extents)
			room.add_child(enemy)
			enemy.set("confined_center_global", room.global_position)
	var npc := Node2D.new()
	npc.name = "RescueNPC_" + sector_type
	npc.set_script(NPC_SCRIPT)
	npc.position = Vector2(0, 15)
	npc.set("npc_name", "Prisionero de " + sector_type)
	rooms[2].add_child(npc)
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
	boss_instance.set("boss_display_name", boss_name)
	boss_instance.set("sector_type", sector_type)
	boss_instance.set("confined_to_room", true)
	var boss_room := get_node_or_null("Sala_6") as Node2D
	if boss_room == null:
		push_warning("No se encontro Sala_6 en el sector " + sector_type)
		return
	var is_rotated := absf(wrapf(boss_room.global_rotation, -PI, PI)) > PI / 4.0 and absf(wrapf(boss_room.global_rotation, -PI, PI)) < 3.0 * PI / 4.0
	var half_extents := Vector2(ROOM_WIDTH / 2.0 - 42.0, ROOM_HEIGHT / 2.0 - 42.0)
	if is_rotated:
		half_extents = Vector2(half_extents.y, half_extents.x)
	boss_instance.set("room_half_extents", half_extents)
	boss_instance.position = Vector2.ZERO
	boss_room.add_child(boss_instance)
	boss_instance.set("confined_center_global", boss_room.global_position)
	print("Minijefe ", boss_name, " colocado y limitado a la sala 6 del sector ", sector_type)
	_spawn_teleport_portal(boss_room)

func _spawn_teleport_portal(boss_room: Node2D) -> void:
	var portal := Area2D.new()
	portal.name = "PortalSectorAleatorio_" + sector_type
	portal.set_script(PORTAL_SCRIPT)
	portal.set("source_sector", sector_type)
	portal.position = Vector2(ROOM_WIDTH / 2.0 - 72.0, ROOM_HEIGHT / 2.0 - 72.0)
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	collision.shape = circle
	portal.add_child(collision)
	boss_room.add_child(portal)
