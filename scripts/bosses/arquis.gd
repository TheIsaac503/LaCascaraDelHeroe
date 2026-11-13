extends CombatantBase
class_name ArquisBoss


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


@export_group("Integración con sectores")

@export var boss_display_name: String = "Arquis"
@export var sector_type: String = "Creatividad"

@export var confined_to_room: bool = true
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)

var confined_center_global: Vector2 = Vector2.ZERO


@export_group("Movimiento y ataques")

@export var movement_speed: float = 38.0
@export var minimum_separation: float = 46.0
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


# Dirección utilizada para saber hacia dónde mira Arquis.
var last_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:

	super._ready()

	add_to_group("enemies")

	_play_idle()

	queue_redraw()


# ==================================================
# ANIMACIONES
# ==================================================

func _play_anim(anim: StringName) -> void:

	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(anim):
		return

	if sprite.animation != anim or not sprite.is_playing():

		sprite.play(anim)


# ==================================================
# MIRAR HACIA IZQUIERDA / DERECHA
# ==================================================

func _update_facing() -> void:

	if sprite == null:
		return


	# Se asume que las animaciones caminar y ataques
	# fueron dibujadas mirando originalmente a la derecha.

	if last_direction.x < -0.1:

		sprite.flip_h = true


	elif last_direction.x > 0.1:

		sprite.flip_h = false


# ==================================================
# MIRAR AL JUGADOR
# ==================================================

func _face_player() -> void:

	if not is_instance_valid(player):
		return


	var direction := player.global_position - global_position


	if direction.length() > 0.01:

		last_direction = direction.normalized()


	_update_facing()


# ==================================================
# IDLE SEGÚN DIRECCIÓN
# ==================================================

func _play_idle() -> void:

	if sprite == null:
		return


	if absf(last_direction.x) > absf(last_direction.y):

		if last_direction.x < 0.0:

			sprite.flip_h = false
			_play_anim(&"idle_izquierda")

		else:

			sprite.flip_h = false
			_play_anim(&"idle_derecha")


	else:

		sprite.flip_h = false


		if last_direction.y < 0.0:

			_play_anim(&"idle_espalda")

		else:

			_play_anim(&"idle_frente")


# ==================================================
# ACTUALIZAR ANIMACIÓN DE MOVIMIENTO
# ==================================================

func _update_visual_motion() -> void:

	if sprite == null or is_dead:
		return


	if velocity.length() > 1.0:

		last_direction = velocity.normalized()

		_update_facing()

		_play_anim(&"caminar")


	else:

		_play_idle()


# ==================================================
# PROCESO PRINCIPAL
# ==================================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	cooldown = maxf(
		0.0,
		cooldown - delta
	)


	_find_player()


	if not is_instance_valid(player):

		velocity = Vector2.ZERO

		_update_visual_motion()

		move_and_slide()

		return


	# ==============================================
	# PREPARANDO ATAQUE
	# ==============================================

	if state == &"preparing":

		velocity = Vector2.ZERO

		_face_player()

		timer -= delta


		if timer <= 0.0:

			_execute_attack()

			state = &"recovering"

			timer = 0.8


		move_and_slide()

		return


	# ==============================================
	# RECUPERACIÓN DESPUÉS DEL ATAQUE
	# ==============================================

	if state == &"recovering":

		velocity = Vector2.ZERO

		timer -= delta


		if timer <= 0.0:

			state = &"idle"


		_play_idle()

		move_and_slide()

		return


	# ==============================================
	# MOVIMIENTO NORMAL
	# ==============================================

	var offset := player.global_position - global_position

	var distance := offset.length()
	if distance <= minimum_separation:
		velocity = Vector2.ZERO
		move_and_slide()
		return


	# Guardamos hacia dónde está Isaac.

	if distance > 0.01:

		last_direction = offset.normalized()


	# Arquis intenta mantener su distancia.

	if distance > preferred_distance:

		# Isaac está demasiado lejos:
		# Arquis retrocede en la dirección contraria.

		velocity = -offset.normalized() * movement_speed


	elif distance < preferred_distance - 35.0:

		# Isaac está demasiado cerca:
		# Arquis se aleja.

		velocity = offset.normalized() * movement_speed * 0.45


	else:

		velocity = Vector2.ZERO


	_update_visual_motion()

	move_and_slide()

	_keep_inside_room()


	# ==============================================
	# COMENZAR SIGUIENTE ATAQUE
	# ==============================================

	if cooldown <= 0.0:

		attack_index = (
			attack_index + 1
		) % 3


		target_position = player.global_position


		state = &"preparing"

		timer = windup

		cooldown = attack_cooldown


# ==================================================
# BUSCAR JUGADOR
# ==================================================

func _find_player() -> void:

	if is_instance_valid(player):
		return


	var candidate := get_tree().get_first_node_in_group(
		"player"
	)


	if candidate is CharacterBody2D:

		player = candidate as CharacterBody2D


# ==================================================
# LIMITAR A LA SALA
# ==================================================

func _keep_inside_room() -> void:

	if not confined_to_room:
		return


	global_position.x = clampf(

		global_position.x,

		confined_center_global.x
			- room_half_extents.x,

		confined_center_global.x
			+ room_half_extents.x
	)


	global_position.y = clampf(

		global_position.y,

		confined_center_global.y
			- room_half_extents.y,

		confined_center_global.y
			+ room_half_extents.y
	)


# ==================================================
# EJECUTAR ATAQUE
# ==================================================

func _execute_attack() -> void:

	match attack_index:

		0:
			_fire_crossbow()

		1:
			_launch_bomb()

		2:
			_deploy_machine()


# ==================================================
# ATAQUE 1 - BALLESTA
# ==================================================

func _fire_crossbow() -> void:

	if not is_instance_valid(player):
		return


	_face_player()

	_play_anim(&"ataque1")


	var direction := global_position.direction_to(
		player.global_position
	)


	_spawn_projectile(

		global_position + direction * 28.0,

		direction,

		crossbow_damage,

		330.0,

		0.0,

		Color("#e2a7f0"),

		6.0
	)


# ==================================================
# ATAQUE 2 - BOMBA
# ==================================================

func _launch_bomb() -> void:

	if not is_instance_valid(player):
		return


	_face_player()

	_play_anim(&"ataque2")


	var direction := global_position.direction_to(
		target_position
	)


	_spawn_projectile(

		global_position + direction * 24.0,

		direction + Vector2(0, -0.55),

		bomb_damage,

		210.0,

		420.0,

		Color("#f0a45c"),

		12.0
	)


# ==================================================
# ATAQUE 3 - MÁQUINA
# ==================================================

func _deploy_machine() -> void:

	if not is_instance_valid(player):
		return


	_face_player()

	_play_anim(&"ataque3")


	var machine := ArquisMachine.new()

	machine.shots_left = 3

	machine.projectile_damage = machine_damage

	machine.player = player


	get_tree().current_scene.add_child(
		machine
	)


	# La máquina aparece en el lado contrario al jugador
	# para que no aparezca encima de Isaac.

	if player.global_position.x > global_position.x:

		machine.global_position = global_position + Vector2(
			-48.0,
			28.0
		)

	else:

		machine.global_position = global_position + Vector2(
			48.0,
			28.0
		)


# ==================================================
# CREAR PROYECTIL
# ==================================================

func _spawn_projectile(

	pos: Vector2,

	dir: Vector2,

	damage: int,

	speed: float,

	gravity_value: float,

	tint: Color,

	size: float

) -> void:


	var projectile := BossProjectile.new()


	projectile.damage = damage

	projectile.velocity = dir.normalized() * speed

	projectile.fall_gravity = gravity_value

	projectile.radius = size


	get_tree().current_scene.add_child(
		projectile
	)


	projectile.global_position = pos


	# Cambiar color del proyectil.

	for child in projectile.get_children():

		if child is Polygon2D:

			child.color = tint


# ==================================================
# RECIBIR DAÑO
# ==================================================

func take_damage(

	amount: int,

	attacker_position: Vector2 = Vector2.ZERO

) -> void:


	if is_dead:
		return


	_play_anim(&"dano")


	super.take_damage(
		amount,
		attacker_position
	)


	queue_redraw()


# ==================================================
# MUERTE
# ==================================================

func _defeat() -> void:

	if is_dead:
		return


	velocity = Vector2.ZERO

	_play_anim(&"muerte")


	super._defeat()


	GameData.grant_soul_fragment(
		"Creatividad"
	)


	GameData.mark_sector_cleared(
		sector_type
	)


# ==================================================
# BARRA DE VIDA
# ==================================================

func _draw() -> void:

	if is_dead:
		return


	var ratio := clampf(

		float(health)
		/ float(max_health),

		0.0,

		1.0
	)


	draw_string(

		ThemeDB.fallback_font,

		Vector2(-55, -55),

		"MINIJEFE: " + boss_display_name,

		HORIZONTAL_ALIGNMENT_CENTER,

		110,

		10,

		Color("#ffe29a")
	)


	draw_rect(

		Rect2(
			-37,
			-46,
			74,
			6
		),

		Color("#421c27")
	)


	draw_rect(

		Rect2(
			-37,
			-46,
			74 * ratio,
			6
		),

		Color("#e2a7f0")
	)
