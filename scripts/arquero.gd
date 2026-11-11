extends CharacterBody2D

@export var speed: float = 65.0
@export var max_health: int = 40
@export var arrow_scene: PackedScene

# Configuración del arquero
@export var attack_range: float = 220.0
@export var preferred_distance: float = 170.0
@export var attack_cooldown: float = 2.0
@export var contact_damage: int = 5

# Integración con las salas generadas por SectorController.
@export var confined_to_room: bool = false
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)
var confined_center_global: Vector2 = Vector2.ZERO

var health: int
var player: CharacterBody2D
var cooldown_timer: float = 0.0
var is_attacking := false
var is_dead := false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	if confined_to_room and confined_center_global == Vector2.ZERO:
		confined_center_global = global_position
	if sprite != null:
		sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	cooldown_timer = maxf(0.0, cooldown_timer - delta)

	if not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty() and players[0] is CharacterBody2D:
			player = players[0] as CharacterBody2D

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_update_animation()
		return

	# Un arquero limitado a una sala permanece inactivo mientras Isaac no esté dentro.
	if confined_to_room and not _is_player_in_room():
		velocity = Vector2.ZERO
		_update_animation()
		return

	var distance := global_position.distance_to(player.global_position)
	var direction := global_position.direction_to(player.global_position)

	if distance > preferred_distance + 20.0:
		velocity = direction * speed
	elif distance < preferred_distance - 20.0:
		velocity = -direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_keep_inside_room()

	if sprite != null and absf(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0.0

	if distance <= attack_range and cooldown_timer <= 0.0 and not is_attacking:
		_shoot_arrow()

	_update_animation()

func _is_player_in_room() -> bool:
	if not is_instance_valid(player):
		return false
	return absf(player.global_position.x - confined_center_global.x) <= room_half_extents.x and absf(player.global_position.y - confined_center_global.y) <= room_half_extents.y

func _keep_inside_room() -> void:
	if not confined_to_room:
		return
	global_position.x = clampf(global_position.x, confined_center_global.x - room_half_extents.x, confined_center_global.x + room_half_extents.x)
	global_position.y = clampf(global_position.y, confined_center_global.y - room_half_extents.y, confined_center_global.y + room_half_extents.y)

func _shoot_arrow() -> void:
	if arrow_scene == null:
		push_warning("Arquero: no se ha asignado la escena de la flecha.")
		return
	if not is_instance_valid(player):
		return

	is_attacking = true
	cooldown_timer = attack_cooldown

	var arrow := arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position
	var direction := global_position.direction_to(player.global_position)
	arrow.direction = direction

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("ataque"):
		sprite.play("ataque")
	else:
		is_attacking = false

func _update_animation() -> void:
	if sprite == null or sprite.sprite_frames == null or is_attacking:
		return
	var animation_name := "idle"
	if velocity.length() > 1.0:
		animation_name = "mover"
	if sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)

func _on_animation_finished() -> void:
	if sprite != null and sprite.animation == "ataque":
		is_attacking = false

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		is_dead = true
		queue_free()
