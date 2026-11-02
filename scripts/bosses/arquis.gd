extends CombatantBase
class_name ArquisBoss

@export_group("Integración con sectores")
@export var boss_display_name: String = "Arquis"
@export var sector_type: String = "Creatividad"
@export var confined_to_room: bool = true
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)
var confined_center_global: Vector2 = Vector2.ZERO

@export_group("Movimiento y ataques")
@export var movement_speed: float = 38.0
@export var preferred_distance: float = 175.0
@export var attack_cooldown: float = 2.0
@export var windup: float = 0.75
@export var crossbow_damage: int = 16
@export var bomb_damage: int = 22
@export var machine_damage: int = 9

var player: CharacterBody2D
var state: StringName = &"idle"
var timer: float = 0.0
var cooldown: float = 1.2
var attack_index: int = -1
var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dead: return
	cooldown = maxf(0.0, cooldown - delta)
	_find_player()
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if state == &"preparing":
		timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if timer <= 0.0:
			_execute_attack()
			state = &"recovering"
			timer = 0.8
		return
	if state == &"recovering":
		timer -= delta
		if timer <= 0.0: state = &"idle"
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var offset := player.global_position - global_position
	if offset.length() > preferred_distance:
		velocity = -offset.normalized() * movement_speed
	elif offset.length() < preferred_distance - 35.0:
		velocity = offset.normalized() * movement_speed * 0.45
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_keep_inside_room()
	if cooldown <= 0.0:
		attack_index = (attack_index + 1) % 3
		target_position = player.global_position
		state = &"preparing"
		timer = windup
		cooldown = attack_cooldown

func _find_player() -> void:
	if is_instance_valid(player): return
	var candidate := get_tree().get_first_node_in_group("player")
	if candidate is CharacterBody2D: player = candidate as CharacterBody2D

func _keep_inside_room() -> void:
	if confined_to_room:
		global_position.x = clampf(global_position.x, confined_center_global.x - room_half_extents.x, confined_center_global.x + room_half_extents.x)
		global_position.y = clampf(global_position.y, confined_center_global.y - room_half_extents.y, confined_center_global.y + room_half_extents.y)

func _execute_attack() -> void:
	match attack_index:
		0: _fire_crossbow()
		1: _launch_bomb()
		2: _deploy_machine()

func _spawn_projectile(pos: Vector2, dir: Vector2, damage: int, speed: float, gravity_value: float, tint: Color, size: float) -> void:
	var projectile := BossProjectile.new()
	projectile.damage = damage
	projectile.velocity = dir * speed
	projectile.fall_gravity = gravity_value
	projectile.radius = size
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = pos
	var visual := projectile.get_child(1) as Polygon2D
	if visual != null: visual.color = tint

func _fire_crossbow() -> void:
	var direction := global_position.direction_to(player.global_position)
	_spawn_projectile(global_position + direction * 28.0, direction, crossbow_damage, 330.0, 0.0, Color("#e2a7f0"), 6.0)

func _launch_bomb() -> void:
	var direction := global_position.direction_to(target_position)
	_spawn_projectile(global_position + direction * 24.0, direction + Vector2(0, -0.55), bomb_damage, 210.0, 420.0, Color("#f0a45c"), 12.0)

func _deploy_machine() -> void:
	var machine := ArquisMachine.new()
	machine.shots_left = 3
	machine.projectile_damage = machine_damage
	machine.player = player
	get_tree().current_scene.add_child(machine)
	machine.global_position = global_position + Vector2(-48.0 if player.global_position.x > global_position.x else 48.0, 28.0)

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead: return
	super.take_damage(amount, attacker_position)
	queue_redraw()

func _defeat() -> void:
	if is_dead: return
	GameData.grant_soul_fragment("Creatividad")
	GameData.mark_sector_cleared(sector_type)
	super._defeat()

func _draw() -> void:
	if is_dead: return
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-55, -55), "MINIJEFE: " + boss_display_name, HORIZONTAL_ALIGNMENT_CENTER, 110, 10, Color("#ffe29a"))
	draw_rect(Rect2(-37, -46, 74, 6), Color("#421c27"))
	draw_rect(Rect2(-37, -46, 74 * ratio, 6), Color("#e2a7f0"))
