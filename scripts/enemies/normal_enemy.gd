extends CombatantBase

## Enemigo normal: IA y ataque propios. No contiene reglas de minijefes.

@export_group("Movimiento")
@export var movement_speed: float = 65.0
@export var detection_range: float = 230.0
@export var stop_distance: float = 31.0

@export_group("Ataque")
@export var contact_damage: int = 10
@export var attack_range: float = 38.0
@export var attack_cooldown_time: float = 1.25
@export var attack_windup: float = 0.22
@export var attack_recovery: float = 0.28

@export_group("Límites de sala")
@export var confined_to_room: bool = false
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)
var confined_center_global: Vector2 = Vector2.ZERO

var player: CharacterBody2D
var attack_cooldown: float = 0.0
var attack_timer: float = 0.0
var attack_has_hit: bool = false
var state: StringName = &"idle"
var hurt_timer: float = 0.0

func _ready() -> void:
	super._ready()
	_play_animation(&"idle")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if hurt_timer > 0.0:
		hurt_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		if hurt_timer <= 0.0:
			state = &"idle"
		return

	_find_player()
	if not is_instance_valid(player):
		state = &"idle"
		velocity = Vector2.ZERO
		move_and_slide()
		_play_animation(&"idle")
		return

	var player_position := player.global_position
	if confined_to_room and not _position_is_inside_room(player_position):
		state = &"idle"
		velocity = Vector2.ZERO
		move_and_slide()
		_play_animation(&"idle")
		return

	var distance_to_player := global_position.distance_to(player_position)
	if distance_to_player > detection_range:
		state = &"idle"
		velocity = Vector2.ZERO
		move_and_slide()
		_play_animation(&"idle")
		return

	if state == &"attacking":
		_process_attack(delta)
		return

	if distance_to_player <= attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		if attack_cooldown <= 0.0:
			_begin_attack()
		else:
			state = &"idle"
			_play_animation(&"idle")
		return

	state = &"chasing"
	var direction := global_position.direction_to(player_position)
	if distance_to_player > stop_distance:
		velocity = direction * movement_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_keep_inside_room()
	_face_direction(direction)
	_play_animation(&"mover")

func _find_player() -> void:
	if is_instance_valid(player):
		return
	var candidate := get_tree().get_first_node_in_group("player")
	if candidate is CharacterBody2D:
		player = candidate as CharacterBody2D

func _position_is_inside_room(world_position: Vector2) -> bool:
	return absf(world_position.x - confined_center_global.x) <= room_half_extents.x and absf(world_position.y - confined_center_global.y) <= room_half_extents.y

func _keep_inside_room() -> void:
	if not confined_to_room:
		return
	global_position.x = clampf(global_position.x, confined_center_global.x - room_half_extents.x, confined_center_global.x + room_half_extents.x)
	global_position.y = clampf(global_position.y, confined_center_global.y - room_half_extents.y, confined_center_global.y + room_half_extents.y)

func _begin_attack() -> void:
	state = &"attacking"
	attack_cooldown = attack_cooldown_time
	attack_timer = attack_windup + attack_recovery
	attack_has_hit = false
	velocity = Vector2.ZERO
	_play_animation(&"attack")

func _process_attack(delta: float) -> void:
	attack_timer -= delta
	if not attack_has_hit and attack_timer <= attack_recovery:
		attack_has_hit = true
		if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range + 8.0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage, global_position)

	if attack_timer <= 0.0:
		state = &"idle"
		_play_animation(&"idle")

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	super.take_damage(amount, attacker_position)
	if is_dead:
		return
	state = &"hurt"
	hurt_timer = 0.16
	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("hurt"):
		animated_sprite.play(&"hurt")

func _face_direction(direction: Vector2) -> void:
	if animated_sprite != null and absf(direction.x) > 0.1:
		animated_sprite.flip_h = direction.x < 0.0

func _play_animation(animation_name: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)
