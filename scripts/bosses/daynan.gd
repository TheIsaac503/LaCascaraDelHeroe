extends CombatantBase
class_name DaynanBoss


# ==================================================
# CONFIGURACIÓN
# ==================================================

@export_group("Información")

@export var boss_display_name := "Daynan"
@export var sector_type := "Honor"


@export_group("Sala")

@export var confined_to_room := true
@export var room_half_extents := Vector2(238.0, 138.0)

var confined_center_global := Vector2.ZERO


@export_group("Movimiento")

@export var movement_speed := 76.0
@export var minimum_separation: float = 46.0


@export_group("Ataques")

@export var attack_cooldown := 1.7

# Tiempo antes de iniciar la animación de ataque.
@export var attack_windup := 0.8

# Duración aproximada de cada ataque.
@export var attack_duration := 0.8

# Momento dentro de la animación en que aparece el golpe.
@export var attack_hit_delay := 0.35


@export var side_damage := 18
@export var horizontal_damage := 20
@export var spin_damage := 22


@export var deshonor_duration := 8.0


# ==================================================
# VARIABLES
# ==================================================

var player: CharacterBody2D

var state: StringName = &"idle"

var timer: float = 1.0

var attack_index: int = 0
var current_attack: int = 0

var target_position := Vector2.ZERO

var indicator: Line2D

var sprite: AnimatedSprite2D

var last_direction := Vector2.RIGHT

var attack_has_hit := false


# ==================================================
# READY
# ==================================================

func _ready() -> void:

	super._ready()

	sprite = get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	add_to_group("enemies")

	_play_idle()

	queue_redraw()


# ==================================================
# BUSCAR AL JUGADOR
# ==================================================

func _find_player() -> void:

	if is_instance_valid(player):
		return

	var found := get_tree().get_first_node_in_group("player")

	if found is CharacterBody2D:

		player = found as CharacterBody2D


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
			"ERROR: Daynan no tiene la animacion: ",
			anim
		)

		return


	if sprite.animation != anim:

		sprite.play(anim)

	elif not sprite.is_playing():

		sprite.play()


# ==================================================
# DIRECCIÓN
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
# IDLE
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
# ATAQUES
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
	# PREPARACIÓN
	# ==============================================

	if state == &"windup":

		velocity = Vector2.ZERO

		_face_player()

		timer -= delta

		move_and_slide()


		if timer <= 0.0:

			_execute_attack()

			_clear_indicator()

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


		# El efecto ocurre después de que la animación
		# ya ha comenzado.
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

			timer = attack_cooldown


		return


	# ==============================================
	# IDLE / MOVIMIENTO
	# ==============================================

	if state == &"idle":

		var offset: Vector2 = player.global_position - global_position
		var distance: float = offset.length()

		if distance <= minimum_separation:
			# No intentar ocupar la misma posición que Isaac.
			velocity = Vector2.ZERO
			_face_player()
			_play_idle()
			move_and_slide()

		elif distance > 105.0:
			last_direction = offset.normalized()
			velocity = last_direction * movement_speed
			_play_walk()
			move_and_slide()
			_clamp_room()

		else:
			velocity = Vector2.ZERO
			_face_player()
			_play_idle()
			move_and_slide()


		timer -= delta


		if timer <= 0.0:

			_start_attack()


# ==================================================
# INICIAR ATAQUE
# ==================================================

func _start_attack() -> void:

	if not is_instance_valid(player):
		return


	current_attack = attack_index

	target_position = player.global_position

	state = &"windup"

	timer = attack_windup

	velocity = Vector2.ZERO

	_face_player()

	_show_warning()


# ==================================================
# ADVERTENCIA DEL ATAQUE
# ==================================================

func _show_warning() -> void:

	_clear_indicator()


	# =================================================
	# ATAQUE 1 - 10 LÍNEAS DE ADVERTENCIA
	# =================================================

	if current_attack == 0:

		var lines := 10
		var spacing := 25.0

		var start_y := (
			target_position.y
			- spacing * 0.5
		)


		for i in range(lines):

			var warning := Line2D.new()

			warning.width = 4.0

			warning.default_color = Color(
				1.0,
				0.85,
				0.3,
				0.65
			)

			warning.z_index = 20


			var line_y := (
				start_y
				+ spacing * i
			)


			warning.points = PackedVector2Array([

				Vector2(
					confined_center_global.x
					- room_half_extents.x,
					line_y
				),

				Vector2(
					confined_center_global.x
					+ room_half_extents.x,
					line_y
				)

			])


			get_tree().current_scene.add_child(
				warning
			)


			# Guardamos todas las advertencias en un grupo.
			warning.add_to_group(
				"daynan_warning"
			)


		return


	# =================================================
	# ATAQUE 2 - LÍNEA VERTICAL
	# =================================================

	if current_attack == 1:

		indicator = Line2D.new()

		indicator.width = 6.0

		indicator.default_color = Color(
			1.0,
			0.85,
			0.3,
			0.8
		)

		indicator.z_index = 20


		indicator.points = PackedVector2Array([

			Vector2(
				target_position.x,
				confined_center_global.y
				- room_half_extents.y
			),

			Vector2(
				target_position.x,
				confined_center_global.y
				+ room_half_extents.y
			)

		])


		get_tree().current_scene.add_child(
			indicator
		)


	# =================================================
	# ATAQUE 3 - CÍRCULO
	# =================================================

	elif current_attack == 2:

		indicator = Line2D.new()

		indicator.width = 6.0

		indicator.default_color = Color(
			1.0,
			0.85,
			0.3,
			0.8
		)

		indicator.z_index = 20


		var pts := PackedVector2Array()


		for i in range(49):

			var angle := (
				TAU
				* float(i)
				/ 48.0
			)


			pts.append(

				global_position

				+ Vector2(
					cos(angle),
					sin(angle)
				) * 105.0

			)


		indicator.points = pts


		get_tree().current_scene.add_child(
			indicator
		)


# ==================================================
# EJECUTAR ATAQUE
# ==================================================

func _execute_attack() -> void:

	velocity = Vector2.ZERO

	_face_player()

	_play_attack_anim()

	attack_has_hit = false


	print(
		"DAYNAN INICIA ATAQUE: ",
		current_attack + 1
	)


# ==================================================
# APLICAR EFECTO DEL ATAQUE
# ==================================================

func _apply_attack_effect() -> void:

	if not is_instance_valid(player):
		return


	print(
		"DAYNAN GOLPEA: ",
		current_attack + 1
	)


	match current_attack:


		# ==========================================
		# ATAQUE 1
		# 10 LÍNEAS HORIZONTALES
		# ==========================================

		0:

			var lines := 5
			var spacing := 25.0

			var start_y := (
				target_position.y
				- spacing * 1.5
			)


			var hit := false


			for i in range(lines):

				var line_y := (
					start_y
					+ spacing * i
				)


				_spawn_attack_line(

					Vector2(
						confined_center_global.x
						- room_half_extents.x,
						line_y
					),

					Vector2(
						confined_center_global.x
						+ room_half_extents.x,
						line_y
					)

				)


				if absf(
					player.global_position.y
					- line_y
				) <= 9.0:

					hit = true


			if hit:

				_damage_player(
					side_damage,
					true
				)


		# ==========================================
		# ATAQUE 2
		# ==========================================

		1:

			_spawn_attack_line(

				Vector2(
					target_position.x,
					confined_center_global.y
					- room_half_extents.y
				),

				Vector2(
					target_position.x,
					confined_center_global.y
					+ room_half_extents.y
				)

			)


			if absf(
				player.global_position.x
				- target_position.x
			) <= 30.0:

				_damage_player(
					horizontal_damage,
					false
				)


		# ==========================================
		# ATAQUE 3
		# ==========================================

		2:

			var distance := global_position.distance_to(
				player.global_position
			)


			if distance <= 105.0:

				_damage_player(
					spin_damage,
					false
				)


	attack_index = (
		attack_index + 1
	) % 3


# ==================================================
# CREAR LÍNEA DE ATAQUE
# ==================================================

func _spawn_attack_line(

	start_point: Vector2,

	end_point: Vector2

) -> void:


	var attack_line := Line2D.new()


	attack_line.width = 6.0


	attack_line.default_color = Color(
		1.0,
		0.15,
		0.15,
		0.95
	)


	attack_line.z_index = 15


	attack_line.points = PackedVector2Array([
		start_point,
		end_point
	])


	get_tree().current_scene.add_child(
		attack_line
	)


	var life_timer := Timer.new()


	life_timer.one_shot = true

	life_timer.wait_time = 0.18


	attack_line.add_child(
		life_timer
	)


	life_timer.timeout.connect(
		attack_line.queue_free
	)


	life_timer.start()


# ==================================================
# DAÑAR JUGADOR
# ==================================================

func _damage_player(

	amount: int,

	applies_deshonor: bool

) -> void:


	if not is_instance_valid(player):
		return


	if player.has_method("take_damage"):

		player.take_damage(
			amount,
			global_position
		)


	if applies_deshonor:

		_apply_deshonor()


# ==================================================
# DESHONOR
# ==================================================

func _apply_deshonor() -> void:

	if not is_instance_valid(player):
		return


	var stacks := mini(

		5,

		int(
			player.get_meta(
				"deshonor_stacks",
				0
			)
		)

		+ 1

	)


	player.set_meta(
		"deshonor_stacks",
		stacks
	)


	if player.get("attack_damage") != null:

		if not player.has_meta(
			"deshonor_damage_original"
		):

			player.set_meta(

				"deshonor_damage_original",

				player.get("attack_damage")

			)


		var original_damage := int(

			player.get_meta(
				"deshonor_damage_original"
			)

		)


		player.set(

			"attack_damage",

			maxi(
				1,
				roundi(
					float(original_damage)
					* (
						1.0
						- 0.1 * stacks
					)
				)
			)

		)


	if player.get("speed") != null:

		if not player.has_meta(
			"deshonor_speed_original"
		):

			player.set_meta(

				"deshonor_speed_original",

				player.get("speed")

			)


		var original_speed := float(

			player.get_meta(
				"deshonor_speed_original"
			)

		)


		player.set(

			"speed",

			original_speed
			* (
				1.0
				- 0.1 * stacks
			)

		)


# ==================================================
# LÍMITES DE SALA
# ==================================================

func _clamp_room() -> void:

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
# LIMPIAR ADVERTENCIAS
# ==================================================

func _clear_indicator() -> void:

	if is_instance_valid(indicator):

		indicator.queue_free()


	indicator = null


	var warnings := get_tree().get_nodes_in_group(
		"daynan_warning"
	)


	for warning in warnings:

		if is_instance_valid(warning):

			warning.queue_free()


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


	_clear_indicator()


	_play_anim(&"muerte")


	super._defeat()


	_remove_deshonor()


	if sector_type != "":

		GameData.grant_soul_fragment(
			"Honor"
		)


	GameData.mark_sector_cleared(
		sector_type
	)


# ==================================================
# QUITAR DESHONOR
# ==================================================

func _remove_deshonor() -> void:

	if not is_instance_valid(player):
		return


	if player.has_meta(
		"deshonor_damage_original"
	):

		player.set(

			"attack_damage",

			player.get_meta(
				"deshonor_damage_original"
			)

		)


		player.remove_meta(
			"deshonor_damage_original"
		)


	if player.has_meta(
		"deshonor_speed_original"
	):

		player.set(

			"speed",

			player.get_meta(
				"deshonor_speed_original"
			)

		)


		player.remove_meta(
			"deshonor_speed_original"
		)


	player.remove_meta(
		"deshonor_stacks"
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

		Vector2(-58, -62),

		"MINIJEFE: DAYNAN",

		HORIZONTAL_ALIGNMENT_CENTER,

		116,

		11,

		Color("#f5df9b")

	)


	draw_rect(

		Rect2(
			-46,
			-53,
			92,
			7
		),

		Color("#3d2432")

	)


	draw_rect(

		Rect2(
			-46,
			-53,
			92 * ratio,
			7
		),

		Color("#d6ad58")

	)
