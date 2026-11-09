extends "res://scripts/enemy.gd"


# ==================================================
# CONFIGURACIÓN
# ==================================================

@export_group("Ataques de Srbos")

@export var attack_damage_1: int = 20
@export var attack_damage_2: int = 16
@export var attack_damage_3: int = 28

@export var attack_range_1: float = 75.0
@export var attack_range_2: float = 120.0
@export var attack_range_3: float = 95.0

@export var attack_cooldown: float = 1.5

# Tiempo antes de comenzar el siguiente ataque.
@export var attack_recovery: float = 0.35


# ==================================================
# VARIABLES
# ==================================================

var attack_timer: float = 0.0

var current_attack: int = 0

var attack_damage_done: bool = false

var last_direction := Vector2.RIGHT


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	super._ready()

	# Nos aseguramos de que Srbos empiece
	# mirando hacia una dirección válida.
	last_direction = Vector2.RIGHT

	_play_idle()


# ==================================================
# BUSCAR JUGADOR
# ==================================================

func _find_player_srbos() -> void:

	if is_instance_valid(player):
		return

	var found := get_tree().get_first_node_in_group(
		"player"
	)

	if found is CharacterBody2D:
		player = found as CharacterBody2D


# ==================================================
# REPRODUCIR ANIMACIÓN
# ==================================================

func _play_anim(
	anim: StringName
) -> void:

	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(anim):

		print(
			"Srbos no tiene la animación: ",
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

		_find_player_srbos()


	if not is_instance_valid(player):
		return


	var direction := (
		player.global_position
		- global_position
	)


	if direction.length() <= 0.01:
		return


	last_direction = direction.normalized()


	if sprite != null:

		if last_direction.x < 0.0:

			sprite.flip_h = true

		elif last_direction.x > 0.0:

			sprite.flip_h = false


# ==================================================
# IDLE DIRECCIONAL
# ==================================================

func _play_idle() -> void:

	if sprite == null:
		return


	if absf(last_direction.x) > absf(last_direction.y):

		if last_direction.x < 0.0:

			sprite.flip_h = true

			_play_anim(
				&"idle_izquierda"
			)

		else:

			sprite.flip_h = false

			_play_anim(
				&"idle_derecha"
			)

	else:

		sprite.flip_h = false


		if last_direction.y < 0.0:

			_play_anim(
				&"idle_espalda"
			)

		else:

			_play_anim(
				&"idle_frente"
			)


# ==================================================
# CAMINAR
# ==================================================

func _play_walk() -> void:

	if sprite == null:
		return


	if velocity.length() > 0.01:

		last_direction = velocity.normalized()


	if last_direction.x < 0.0:

		sprite.flip_h = true

	elif last_direction.x > 0.0:

		sprite.flip_h = false


	_play_anim(
		&"caminar"
	)


# ==================================================
# ANIMACIÓN DEL ATAQUE
# ==================================================

func _play_attack_animation() -> void:

	_face_player()


	match current_attack:

		0:
			_play_anim(
				&"ataque1"
			)

		1:
			_play_anim(
				&"ataque2"
			)

		2:
			_play_anim(
				&"ataque3"
			)


# ==================================================
# INICIAR ATAQUE
# ==================================================

func _attack_player() -> void:

	if is_dead:
		return


	if is_attacking:
		return


	if attack_timer > 0.0:
		return


	_find_player_srbos()


	if not is_instance_valid(player):
		return


	# Detener movimiento.
	velocity = Vector2.ZERO


	# Elegir el siguiente ataque.
	current_attack = (
		current_attack + 1
	) % 3


	# Activar estado de ataque.
	is_attacking = true

	attack_damage_done = false


	_face_player()


	# Reproducir animación.
	_play_attack_animation()


# ==================================================
# ANIMACIÓN TERMINADA
# ==================================================

func _on_animation_finished() -> void:

	if sprite == null:
		return


	if not is_attacking:
		return


	if (

		sprite.animation == &"ataque1"

		or sprite.animation == &"ataque2"

		or sprite.animation == &"ataque3"

	):

		# Por seguridad, aplicar el golpe si la
		# animación terminó antes de activar el daño.
		if not attack_damage_done:

			_apply_attack_damage()


		is_attacking = false

		attack_timer = attack_cooldown


# ==================================================
# APLICAR EL DAÑO
# ==================================================

func _apply_attack_damage() -> void:

	if attack_damage_done:
		return


	if not is_instance_valid(player):
		return


	attack_damage_done = true


	var distance := (
		global_position.distance_to(
			player.global_position
		)
	)


	match current_attack:


		# ==========================================
		# ATAQUE 1
		# ==========================================

		0:

			if distance <= attack_range_1:

				_damage_player(
					attack_damage_1
				)


		# ==========================================
		# ATAQUE 2
		# ==========================================

		1:

			if distance <= attack_range_2:

				_damage_player(
					attack_damage_2
				)


		# ==========================================
		# ATAQUE 3
		# ==========================================

		2:

			if distance <= attack_range_3:

				_damage_player(
					attack_damage_3
				)


# ==================================================
# DAÑAR AL JUGADOR
# ==================================================

func _damage_player(
	amount: int
) -> void:

	if not is_instance_valid(player):
		return


	if player.has_method(
		"take_damage"
	):

		player.take_damage(
			amount
		)


# ==================================================
# CONTROL DEL ATAQUE
# ==================================================

func _physics_process(
	delta: float
) -> void:

	attack_timer = maxf(
		0.0,
		attack_timer - delta
	)


	# Mientras ataca, el padre no debe reemplazar
	# la animación por caminar o idle.
	if is_attacking:

		velocity = Vector2.ZERO

		_play_attack_animation()


		# Aplicamos el daño aproximadamente a la mitad
		# de la animación.
		if sprite != null:

			var total_frames := (
				sprite.sprite_frames.get_frame_count(
					sprite.animation
				)
			)


			if total_frames > 0:

				var hit_frame := maxi(
					1,
					total_frames / 2
				)


				if (
					sprite.frame >= hit_frame

					and not attack_damage_done

				):

					_apply_attack_damage()


		return


	# Movimiento normal del enemigo.
	super._physics_process(
		delta
	)


# ==================================================
# CONTROL DE ANIMACIONES NORMALES
# ==================================================

func _update_animation() -> void:

	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if is_dead:
		return


	# Nunca reemplazar una animación de ataque.
	if is_attacking:
		return


	if velocity.length() > 1.0:

		last_direction = velocity.normalized()

		_play_walk()

	else:

		_play_idle()
