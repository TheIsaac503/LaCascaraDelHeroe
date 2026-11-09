extends CombatantBase
class_name AcaleniaBoss

@export var boss_display_name := "Acalenia"
@export var sector_type := "Bondad"

@export var confined_to_room := true
@export var room_half_extents := Vector2(238.0, 138.0)
var confined_center_global := Vector2.ZERO

@export var movement_speed := 62.0
@export var attack_cooldown := 2.2

@export var whip_damage := 16
@export var spin_damage := 14
@export var hug_damage := 24

@export var whip_range := 210.0
@export var spin_duration := 4.0
@export var spin_rest := 4.0

var player: CharacterBody2D

# ESTADO
var state: StringName = &"idle_frente"
var timer := 1.0
var attack_index := 0

# ABRAZO
var far_timer := 0.0
var hug_ready := false

# GIRO
var spin_active := false
var spin_resting := false
var spin_hit_timer := 0.0

# VISUAL
var sprite: AnimatedSprite2D
var last_direction := Vector2.DOWN


func _ready() -> void:
	super._ready()

	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	add_to_group("enemies")

	_play_anim(&"idle_frente")


func _play_anim(anim: StringName) -> void:
	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)


# --------------------------------------------------
# DIRECCION VISUAL
# --------------------------------------------------

func _update_facing() -> void:
	if sprite == null:
		return

	# Los ataques y caminar están dibujados mirando
	# hacia la derecha originalmente.
	if last_direction.x < -0.1:
		sprite.flip_h = true

	elif last_direction.x > 0.1:
		sprite.flip_h = false


func _face_player() -> void:
	if not is_instance_valid(player):
		return

	var direction := player.global_position - global_position

	if direction.length() > 0.1:
		last_direction = direction.normalized()

	_update_facing()


func _update_visual_motion() -> void:
	if sprite == null or is_dead:
		return

	# MOVIMIENTO
	if velocity.length() > 1.0:

		last_direction = velocity.normalized()

		_update_facing()

		_play_anim(&"caminar")

		return

	# IDLE SEGUN LA ULTIMA DIRECCION

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


# --------------------------------------------------
# LOGICA PRINCIPAL
# --------------------------------------------------

func _physics_process(delta: float) -> void:

	if is_dead:
		return


	# --------------------------------------------------
	# BUSCAR JUGADOR
	# --------------------------------------------------

	if not is_instance_valid(player):

		var found := get_tree().get_first_node_in_group("player")

		if found is CharacterBody2D:
			player = found


	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_update_visual_motion()
		return


	var distance := global_position.distance_to(player.global_position)


	# --------------------------------------------------
	# PREPARAR ABRAZO
	# --------------------------------------------------

	if distance > 175.0:

		far_timer += delta

		if far_timer >= 3.0:
			hug_ready = true


	# --------------------------------------------------
	# ATAQUE 1 - LATIGO
	# --------------------------------------------------

	if state == &"whip":

		velocity = Vector2.ZERO

		_face_player()

		_play_anim(&"ataque1")

		timer -= delta

		if timer <= 0.0:

			_whip_damage()

			state = &"idle_frente"

			timer = attack_cooldown


		move_and_slide()

		return


	# --------------------------------------------------
	# ATAQUE 2 - GIRO
	# --------------------------------------------------

	if state == &"spin":

		velocity = Vector2.ZERO

		_face_player()

		_play_anim(&"ataque2")

		timer -= delta

		spin_hit_timer = maxf(
			0.0,
			spin_hit_timer - delta
		)


		if spin_hit_timer <= 0.0 and distance <= 82.0:

			_damage_player(spin_damage)

			spin_hit_timer = 0.8


		if timer <= 0.0:

			spin_active = false

			spin_resting = true

			state = &"rest"

			timer = spin_rest


		move_and_slide()

		return


	# --------------------------------------------------
	# DESCANSO DESPUES DEL GIRO
	# --------------------------------------------------

	if state == &"rest":

		velocity = Vector2.ZERO

		_update_visual_motion()

		timer -= delta


		if timer <= 0.0:

			spin_resting = false

			state = &"idle_frente"

			timer = 1.0


		return


	# --------------------------------------------------
	# ATAQUE 3 - ABRAZO
	# --------------------------------------------------

	if state == &"hug":

		velocity = Vector2.ZERO

		_face_player()

		_play_anim(&"ataque3")

		timer -= delta


		if timer <= 0.0:

			if is_instance_valid(player):

				_damage_player(hug_damage)


			state = &"idle_frente"

			timer = attack_cooldown


		move_and_slide()

		return


	# --------------------------------------------------
	# ACTIVAR ABRAZO
	# --------------------------------------------------

	if hug_ready and distance < 58.0:

		state = &"hug"

		timer = 0.7

		hug_ready = false

		far_timer = 0.0

		return


	# --------------------------------------------------
	# MOVIMIENTO NORMAL
	# --------------------------------------------------

	if distance > 125.0:

		velocity = (
			player.global_position - global_position
		).normalized() * movement_speed


		_update_visual_motion()

		move_and_slide()

		_clamp_room()


	# --------------------------------------------------
	# CERCA DEL JUGADOR
	# --------------------------------------------------

	else:

		velocity = Vector2.ZERO

		_update_visual_motion()

		move_and_slide()

		timer -= delta


		if timer <= 0.0:

			if attack_index == 0:

				state = &"whip"

				timer = 0.65


			else:

				state = &"spin"

				timer = spin_duration

				spin_active = true

				spin_hit_timer = 0.0


			attack_index = (
				attack_index + 1
			) % 2


# --------------------------------------------------
# DAÑO DEL ATAQUE 1
# --------------------------------------------------

func _whip_damage() -> void:

	if not is_instance_valid(player):
		return


	var offset := player.global_position - global_position


	# El ataque puede golpear dentro del alcance.
	if offset.length() <= whip_range:

		_damage_player(whip_damage)

		player.velocity = (
			player.global_position - global_position
		).normalized() * 260.0


# --------------------------------------------------
# DAÑAR JUGADOR
# --------------------------------------------------

func _damage_player(amount: int) -> void:

	if is_instance_valid(player):

		if player.has_method("take_damage"):

			player.take_damage(
				amount,
				global_position
			)


# --------------------------------------------------
# LIMITAR A LA SALA
# --------------------------------------------------

func _clamp_room() -> void:

	if not confined_to_room:
		return


	global_position.x = clampf(
		global_position.x,
		confined_center_global.x - room_half_extents.x,
		confined_center_global.x + room_half_extents.x
	)


	global_position.y = clampf(
		global_position.y,
		confined_center_global.y - room_half_extents.y,
		confined_center_global.y + room_half_extents.y
	)


# --------------------------------------------------
# RECIBIR DAÑO
# --------------------------------------------------

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


# --------------------------------------------------
# MUERTE
# --------------------------------------------------

func _defeat() -> void:

	if is_dead:
		return


	velocity = Vector2.ZERO

	_play_anim(&"muerte")

	super._defeat()


	if is_dead and sector_type != "":

		GameData.grant_soul_fragment("Bondad")


	GameData.mark_sector_cleared(sector_type)

	_drop_bondad_potion()


# --------------------------------------------------
# RECOMPENSA
# --------------------------------------------------

func _drop_bondad_potion() -> void:

	var potion := Area2D.new()

	potion.collision_layer = 0

	potion.collision_mask = 2


	var collision := CollisionShape2D.new()

	var circle := CircleShape2D.new()

	circle.radius = 18.0

	collision.shape = circle

	potion.add_child(collision)


	var visual := Polygon2D.new()

	visual.polygon = PackedVector2Array([
		Vector2(0, -11),
		Vector2(8, -5),
		Vector2(6, 9),
		Vector2(-6, 9),
		Vector2(-8, -5)
	])

	visual.color = Color("#83df91")

	potion.add_child(visual)


	potion.body_entered.connect(
		_on_potion_collected.bind(potion)
	)


	get_tree().current_scene.add_child(potion)

	potion.global_position = global_position


func _on_potion_collected(
	body: Node2D,
	potion: Area2D
) -> void:

	if not body.is_in_group("player"):
		return


	var max_hp := int(body.get("max_health"))

	var hp := int(body.get("health"))


	body.set(
		"health",
		mini(
			max_hp,
			hp + maxi(
				1,
				roundi(float(max_hp) * 0.1)
			)
		)
	)


	if body.has_signal("health_changed"):

		body.emit_signal(
			"health_changed",
			body.get("health"),
			body.get("max_health")
		)


	if body.get("base_attack_cooldown") != null:

		var stacks := mini(
			10,
			int(
				body.get_meta(
					"bondad_potion_stacks",
					0
				)
			) + 1
		)


		body.set_meta(
			"bondad_potion_stacks",
			stacks
		)


		if not body.has_meta("bondad_base_cooldown"):

			body.set_meta(
				"bondad_base_cooldown",
				body.get("base_attack_cooldown")
			)


		var original_cooldown := float(
			body.get_meta(
				"bondad_base_cooldown"
			)
		)


		body.set(
			"base_attack_cooldown",
			maxf(
				0.12,
				original_cooldown * (
					1.0 - 0.05 * stacks
				)
			)
		)


	potion.queue_free()


# --------------------------------------------------
# BARRA DE VIDA
# --------------------------------------------------

func _draw() -> void:

	if is_dead:
		return


	var ratio := clampf(
		float(health) / float(max_health),
		0.0,
		1.0
	)


	draw_string(
		ThemeDB.fallback_font,
		Vector2(-58, -62),
		"MINIJEFE: ACALENIA",
		HORIZONTAL_ALIGNMENT_CENTER,
		116,
		11,
		Color("#d8ffd9")
	)


	draw_rect(
		Rect2(-46, -53, 92, 7),
		Color("#3d2432")
	)


	draw_rect(
		Rect2(-46, -53, 92 * ratio, 7),
		Color("#71d68a")
	)
