extends CombatantBase
class_name RadiusBoss


# ==================================================
# CONFIGURACIÓN
# ==================================================

@export_group("Integración con sectores")

@export var boss_display_name: String = "Radius"
@export var sector_type: String = "Ira"

@export var confined_to_room: bool = true
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)

var confined_center_global: Vector2 = Vector2.ZERO


@export_group("Movimiento")

@export var movement_speed: float = 58.0
@export var minimum_separation: float = 46.0


@export_group("Ataques")

@export var charge_damage: int = 24
@export var rock_damage: int = 15

@export var repel_threshold: float = 0.25
@export var repel_force: float = 250.0

@export var attack_cooldown: float = 2.0
@export var windup: float = 0.7

# Tiempo que dura visualmente cada ataque.
@export var attack_duration: float = 0.8

# Momento dentro de la animación donde ocurre el efecto.
@export var attack_hit_delay: float = 0.35

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
# ==================================================
# VARIABLES
# ==================================================

var player: CharacterBody2D

var state: StringName = &"idle"

var timer: float = 1.0
var cooldown: float = 1.0

var attack_index: int = -1
var current_attack: int = 0

var target_position: Vector2 = Vector2.ZERO

var next_repel_health: int = 0

var last_direction := Vector2.RIGHT

var attack_has_hit := false


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	super._ready()

	next_repel_health = maxi(
		1,
		int(
			ceil(
				float(max_health)
				* (1.0 - repel_threshold)
			)
		)
	)

	_play_idle()

	queue_redraw()


# ==================================================
# BUSCAR AL JUGADOR
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
# ANIMACIONES
# ==================================================

func _play_anim(anim: StringName) -> void:

	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(anim):

		print(
			"Radius no tiene la animación: ",
			anim
		)

		return


	if sprite.animation != anim:

		sprite.play(anim)

	elif not sprite.is_playing():

		sprite.play()


# ==================================================
# MIRAR AL JUGADOR
# ==================================================

func _face_player() -> void:

	if not is_instance_valid(player):
		return

	var direction := (
		player.global_position
		- global_position
	)

	if direction.length() > 0.01:

		last_direction = direction.normalized()


# ==================================================
# IDLE DIRECCIONAL
# ==================================================

func _play_idle() -> void:

	if sprite == null:
		return


	if absf(last_direction.x) > absf(last_direction.y):

		if last_direction.x < 0.0:

			sprite.flip_h = true

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
# CAMINAR
# ==================================================

func _play_walk() -> void:

	if sprite == null:
		return


	if last_direction.x < 0.0:

		sprite.flip_h = true

	elif last_direction.x > 0.0:

		sprite.flip_h = false


	_play_anim(&"caminar")


# ==================================================
# ANIMACIÓN DE ATAQUE
# ==================================================

func _play_attack_anim() -> void:

	if sprite == null:
		return


	if last_direction.x < 0.0:

		sprite.flip_h = true

	elif last_direction.x > 0.0:

		sprite.flip_h = false


	match current_attack:

		0:
			_play_anim(&"ataque1")

		1:
			_play_anim(&"ataque2")

		2:
			_play_anim(&"ataque3")


# ==================================================
# PROCESO PRINCIPAL
# ==================================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	_find_player()


	if not is_instance_valid(player):

		velocity = Vector2.ZERO

		_play_idle()

		move_and_slide()

		return


	# ==============================================
	# ATAQUE ESPECIAL DE REPULSIÓN
	# ==============================================

	if state == &"repelling":

		velocity = Vector2.ZERO

		_play_attack_anim()

		timer -= delta

		move_and_slide()


		if not attack_has_hit:

			var elapsed := (
				attack_duration - timer
			)


			if elapsed >= attack_hit_delay:

				_apply_repel()

				attack_has_hit = true


		if timer <= 0.0:

			state = &"idle"

			timer = 0.5


		return


	# ==============================================
	# PREPARACIÓN DEL ATAQUE
	# ==============================================

	if state == &"preparing":

		velocity = Vector2.ZERO

		_face_player()

		timer -= delta

		move_and_slide()


		if timer <= 0.0:

			_execute_attack()

			state = &"attacking"

			timer = attack_duration

			attack_has_hit = false


		return


	# ==============================================
	# ATAQUE
	# ==============================================

	if state == &"attacking":

		velocity = Vector2.ZERO

		_play_attack_anim()

		timer -= delta


		if not attack_has_hit:

			var elapsed := (
				attack_duration - timer
			)


			if elapsed >= attack_hit_delay:

				_apply_attack_effect()

				attack_has_hit = true


		move_and_slide()


		if timer <= 0.0:

			state = &"idle"

			timer = 0.3


		return


	# ==============================================
	# IDLE / MOVIMIENTO
	# ==============================================

	cooldown = maxf(
		0.0,
		cooldown - delta
	)


	var offset := (
		player.global_position
		- global_position
	)


	var distance := offset.length()
	if distance <= minimum_separation:
		velocity = Vector2.ZERO
		move_and_slide()
		return


	if distance > 65.0:

		last_direction = offset.normalized()

		velocity = (
			last_direction
			* movement_speed
		)

		_play_walk()


	else:

		velocity = Vector2.ZERO

		_face_player()

		_play_idle()


	move_and_slide()

	_keep_inside_room()


	if cooldown <= 0.0:

		attack_index = (
			attack_index + 1
		) % 2


		current_attack = attack_index

		target_position = player.global_position

		state = &"preparing"

		timer = windup

		cooldown = attack_cooldown


# ==================================================
# EJECUTAR ATAQUE
# ==================================================

func _execute_attack() -> void:

	velocity = Vector2.ZERO

	_face_player()

	_play_attack_anim()

	attack_has_hit = false


# ==================================================
# EFECTO DEL ATAQUE
# ==================================================

func _apply_attack_effect() -> void:

	match current_attack:


		# ==========================================
		# ATAQUE 1 - CARGA
		# ==========================================

		0:

			_charge()


		# ==========================================
		# ATAQUE 2 - ROCAS
		# ==========================================

		1:

			_throw_rocks()


# ==================================================
# ATAQUE 1
# CARGA
# ==================================================

func _charge() -> void:

	if not is_instance_valid(player):
		return


	var direction := (
		global_position.direction_to(
			target_position
		)
	)


	if direction.length() <= 0.01:

		direction = last_direction


	var start_position := global_position


	# Radius se desplaza hacia adelante.
	global_position += (
		direction * 125.0
	)


	_keep_inside_room()


	# Si Isaac está cerca de la trayectoria,
	# recibe daño.
	var player_distance := (
		player.global_position.distance_to(
			global_position
		)
	)


	if player_distance < 85.0:

		_damage_player(
			charge_damage
		)


# ==================================================
# ATAQUE 2
# LANZAR ROCAS
# ==================================================

func _throw_rocks() -> void:

	if not is_instance_valid(player):
		return


	var base_direction := (
		global_position.direction_to(
			target_position
		)
	)


	if base_direction.length() <= 0.01:

		base_direction = last_direction


	# Tres rocas en abanico.
	for angle in [

		-0.22,

		0.0,

		0.22

	]:

		var rock := BossProjectile.new()


		rock.damage = rock_damage


		rock.velocity = (

			base_direction.rotated(angle)

			* 235.0

			+ Vector2(0, -80.0)

		)


		rock.fall_gravity = 260.0

		rock.radius = 9.0


		get_tree().current_scene.add_child(
			rock
		)


		rock.global_position = (

			global_position

			+ base_direction * 25.0

		)


		var visual := (
			rock.get_child(1)
			as Polygon2D
		)


		if visual != null:

			visual.color = Color(
				"#b98b72"
			)


# ==================================================
# DAÑAR AL JUGADOR
# ==================================================

func _damage_player(
	amount: int
) -> void:

	if not is_instance_valid(player):
		return


	if player.has_method("take_damage"):

		player.take_damage(
			amount,
			global_position
		)


# ==================================================
# RECIBIR DAÑO
# ==================================================

func take_damage(

	amount: int,

	attacker_position: Vector2 = Vector2.ZERO

) -> void:


	if is_dead:
		return


	var old_health := health


	super.take_damage(
		amount,
		attacker_position
	)


	if is_dead:
		return


	# Animación de daño solamente
	# si no está realizando un ataque.
	if state == &"idle":

		_play_anim(&"dano")


	# ==============================================
	# ACTIVAR REPULSIÓN
	# ==============================================

	if (

		health <= next_repel_health

		and old_health > next_repel_health

	):

		current_attack = 2

		state = &"repelling"

		timer = attack_duration

		attack_has_hit = false

		velocity = Vector2.ZERO

		_face_player()

		_play_attack_anim()


		next_repel_health = maxi(

			0,

			next_repel_health

			- int(
				ceil(
					float(max_health)
					* repel_threshold
				)
			)

		)


	queue_redraw()


# ==================================================
# ATAQUE 3
# REPULSIÓN
# ==================================================

func _apply_repel() -> void:

	if not is_instance_valid(player):

		_find_player()


	if not is_instance_valid(player):
		return


	var direction := (

		player.global_position
		- global_position

	).normalized()


	# Empuja a Isaac.
	player.velocity = (
		direction
		* repel_force
	)


# ==================================================
# LÍMITES DE LA SALA
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
# MUERTE
# ==================================================

func _defeat() -> void:

	if is_dead:
		return


	velocity = Vector2.ZERO

	_play_anim(&"muerte")


	GameData.grant_soul_fragment(
		"Ira"
	)


	GameData.mark_sector_cleared(
		sector_type
	)


	super._defeat()


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

		"MINIJEFE: "
		+ boss_display_name,

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

		Color("#e06b43")

	)
