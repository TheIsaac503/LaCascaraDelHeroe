@tool
extends Node2D

@export var sector_type: String = "Ira"
@export var is_first_sector: bool = false
@export var is_last_sector: bool = false

const ROOM_WIDTH := 1000.0
const ROOM_HEIGHT := 620.0
const WALL_THICKNESS := 24.0
const DOOR_GAP := 150.0
const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const ARCHER_SCENE := preload("res://scenes/enemies/Arquero.tscn")
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

# Progresión del sector: Sala 6 se desbloquea al derrotar el 80% de los enemigos normales.
const BOSS_UNLOCK_PERCENT := 0.80
var sector_enemy_total: int = 0
var sector_enemy_defeated: int = 0
var boss_entrance_blocker: StaticBody2D
var boss_entrance_label: Label
var boss_entrance_unlocked := false

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
	# Salas ampliadas: encuentros más grandes y distribuidos.
	var enemy_positions := {
		1: [Vector2(-220, -100), Vector2(190, 90), Vector2(-40, 140)],
		2: [Vector2(-280, -120), Vector2(-80, 100), Vector2(180, -80), Vector2(300, 130)],
		3: [Vector2(-300, 0), Vector2(-120, -150), Vector2(80, 120), Vector2(280, -40), Vector2(20, 200)],
		4: [Vector2(-320, -130), Vector2(-150, 130), Vector2(40, -170), Vector2(180, 80), Vector2(330, 160), Vector2(0, 0)],
		5: [Vector2(-340, -150), Vector2(-220, 120), Vector2(-70, -30), Vector2(100, 150), Vector2(240, -120), Vector2(350, 40), Vector2(20, 230)]
	}
	# Arqueros añadidos a las salas de combate. Se colocan junto a enemigos
	# normales para variar los encuentros sin sobrecargar las primeras salas.
	var archer_positions := {
		1: [Vector2(260, -140)],
		2: [Vector2(0, -190), Vector2(360, 170)],
		3: [Vector2(-360, 170), Vector2(330, -170)],
		4: [Vector2(-300, 190), Vector2(300, -190)],
		5: [Vector2(-360, 0), Vector2(360, 0), Vector2(0, -220)]
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
			_track_sector_enemy(enemy)
	# Crear arqueros como hijos de su propia sala para que no persigan a Isaac
	# por todo el mapa ni disparen desde otros sectores.
	for room_number in archer_positions.keys():
		var room := get_node_or_null("Sala_" + str(room_number)) as Node2D
		if room == null:
			continue
		for local_offset in archer_positions[room_number]:
			var archer := ARCHER_SCENE.instantiate()
			archer.position = local_offset
			archer.set("confined_to_room", true)
			var archer_extents := Vector2(ROOM_WIDTH / 2.0 - 42.0, ROOM_HEIGHT / 2.0 - 42.0)
			var room_angle := absf(wrapf(room.global_rotation, -PI, PI))
			if room_angle > PI / 4.0 and room_angle < 3.0 * PI / 4.0:
				archer_extents = Vector2(archer_extents.y, archer_extents.x)
			archer.set("room_half_extents", archer_extents)
			room.add_child(archer)
			archer.set("confined_center_global", room.global_position)
			_track_sector_enemy(archer)
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

	# El minijefe queda completamente inactivo hasta que Isaac entra en Sala_6.
	# Así no puede perseguir, atacar ni ejecutar habilidades desde otro sector.
	boss_instance.process_mode = Node.PROCESS_MODE_DISABLED
	boss_instance.set_meta("battle_active", false)
	_create_boss_entrance_blocker()
	_create_boss_activation_zone(boss_room, boss_instance)

	print("Minijefe ", boss_name, " colocado en Sala_6 e inactivo hasta que Isaac entre al sector.")
	_spawn_teleport_portal(boss_room)

func _track_sector_enemy(enemy: Node) -> void:
	sector_enemy_total += 1
	enemy.tree_exited.connect(func() -> void:
		if not enemy.has_meta("sector_counted_defeat"):
			enemy.set_meta("sector_counted_defeat", true)
			sector_enemy_defeated += 1
			_update_boss_unlock()
	)

func _update_boss_unlock() -> void:
	if boss_entrance_unlocked or sector_enemy_total <= 0:
		return
	var progress := float(sector_enemy_defeated) / float(sector_enemy_total)
	if progress >= BOSS_UNLOCK_PERCENT:
		boss_entrance_unlocked = true
		if is_instance_valid(boss_entrance_blocker):
			boss_entrance_blocker.queue_free()
		if is_instance_valid(boss_entrance_label):
			boss_entrance_label.queue_free()
		print("Sala 6 desbloqueada en ", sector_type, ": ", sector_enemy_defeated, "/", sector_enemy_total)

func _create_boss_entrance_blocker() -> void:
	var room5 := get_node_or_null("Sala_5") as Node2D
	var room6 := get_node_or_null("Sala_6") as Node2D
	if room5 == null or room6 == null:
		return

	# La barrera debe pertenecer a Sala_6. De esta manera, aunque las salas se
	# reordenen manualmente en el editor, el bloqueo siempre queda pegado a la
	# entrada real de la sala del minijefe y se mueve/rota junto con ella.
	var room5_local := room6.to_local(room5.global_position)
	var use_horizontal_entrance := absf(room5_local.x) >= absf(room5_local.y)

	boss_entrance_blocker = StaticBody2D.new()
	boss_entrance_blocker.name = "BossEntranceLocked_" + sector_type
	boss_entrance_blocker.collision_layer = 1
	boss_entrance_blocker.collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()

	if use_horizontal_entrance:
		# Sala_5 está a la izquierda o derecha de Sala_6.
		var side := signf(room5_local.x)
		if is_zero_approx(side):
			side = -1.0
		boss_entrance_blocker.position = Vector2(
			side * (ROOM_WIDTH / 2.0 - WALL_THICKNESS),
			0.0
		)
		shape.size = Vector2(WALL_THICKNESS * 2.0, DOOR_GAP + 40.0)
	else:
		# Sala_5 está arriba o abajo de Sala_6.
		var side := signf(room5_local.y)
		if is_zero_approx(side):
			side = -1.0
		boss_entrance_blocker.position = Vector2(
			0.0,
			side * (ROOM_HEIGHT / 2.0 - WALL_THICKNESS)
		)
		shape.size = Vector2(DOOR_GAP + 40.0, WALL_THICKNESS * 2.0)

	collision.shape = shape
	boss_entrance_blocker.add_child(collision)
	room6.add_child(boss_entrance_blocker)

	boss_entrance_label = Label.new()
	boss_entrance_label.name = "BossEntranceLabel_" + sector_type
	boss_entrance_label.text = "SALA 6 BLOQUEADA\nDerrota al 80% de los enemigos"
	boss_entrance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_entrance_label.size = Vector2(340, 60)
	boss_entrance_label.modulate = accent.get(sector_type, Color.WHITE)

	if use_horizontal_entrance:
		boss_entrance_label.position = boss_entrance_blocker.position + Vector2(-170, -70)
	else:
		boss_entrance_label.position = boss_entrance_blocker.position + Vector2(-170, -70)

	room6.add_child(boss_entrance_label)

func _create_boss_activation_zone(boss_room: Node2D, boss_instance: Node) -> void:
	var zone := Area2D.new()
	zone.name = "BossActivationZone_" + sector_type
	zone.collision_layer = 0
	zone.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(ROOM_WIDTH - 56.0, ROOM_HEIGHT - 56.0)
	collision.shape = shape
	zone.add_child(collision)
	boss_room.add_child(zone)

	zone.body_entered.connect(func(body: Node2D) -> void:
		if not body.is_in_group("player"):
			return
		if not is_instance_valid(boss_instance):
			zone.queue_free()
			return
		if not boss_entrance_unlocked:
			return
		if bool(boss_instance.get_meta("battle_active", false)):
			return
		boss_instance.set_meta("battle_active", true)
		boss_instance.process_mode = Node.PROCESS_MODE_INHERIT
		print("Combate iniciado contra ", boss_instance.get("boss_display_name"), " en el sector ", sector_type)
		zone.queue_free()
	)

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
