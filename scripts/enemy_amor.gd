extends CharacterBody2D

@export var speed: float = 65.0
@export var max_health: int = 40
@export var contact_damage: int = 10
@export var boss_display_name: String = ""
@export var sector_type: String = ""
@export var confined_to_room: bool = false
@export var room_half_extents: Vector2 = Vector2(238, 138)

# --- Apariencia (sprites animados) ---
# Escala del AnimatedSprite2D. Slime: 1.0 | Srbos: 1.0 (su sprite ya es grande)
@export var sprite_scale: float = 1.0
# Posición y ancho de la barra de vida. Slime: -26 / 30 | Srbos: -66 / 70
@export var bar_offset_y: float = -26.0
@export var bar_width: float = 30.0
# Distancia (centro a centro) a la que el enemigo daña a Isaac al tocarlo.
# Con enemigos grandes súbela: su colisión los mantiene más lejos de Isaac.
@export var contact_range: float = 35.0
# Animación por código para sprites de un solo cuadro (minijefes).
# pulse_amount: cuánto "respira" el sprite (0.03 = 3%). bob_amount: balanceo vertical en px.
@export var pulse_amount: float = 0.0
@export var bob_amount: float = 0.0

var confined_center_global: Vector2 = Vector2.ZERO

var health: int
var player: CharacterBody2D
var contact_cooldown: float = 0.0
var is_dead := false
var base_scale := Vector2.ONE
var anim_time := 0.0
var squash_tween: Tween

# Nodo opcional: si la escena no tiene AnimatedSprite2D, el script sigue
# funcionando con el dibujo antiguo (_draw).
# Animaciones esperadas en su SpriteFrames: "mover" (obligatoria) e "idle" (opcional)
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	if sprite != null:
		base_scale = Vector2.ONE * sprite_scale
		sprite.scale = base_scale
		_update_animation()
	queue_redraw()

func _physics_process(delta: float) -> void:
	contact_cooldown = maxf(0.0, contact_cooldown - delta)

	if not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player = players[0] as CharacterBody2D

	if is_instance_valid(player):
		var target_position := player.global_position
		var direction := global_position.direction_to(target_position)
		# Si el enemigo está limitado a una sala, solo persigue cuando Isaac
		# se encuentra dentro de los límites de esa misma sala.
		if confined_to_room:
			var player_in_room := absf(target_position.x - confined_center_global.x) <= room_half_extents.x and absf(target_position.y - confined_center_global.y) <= room_half_extents.y
			if player_in_room:
				velocity = direction * speed
			else:
				velocity = Vector2.ZERO
		else:
			velocity = direction * speed
		move_and_slide()
		if confined_to_room:
			global_position.x = clampf(global_position.x, confined_center_global.x - room_half_extents.x, confined_center_global.x + room_half_extents.x)
			global_position.y = clampf(global_position.y, confined_center_global.y - room_half_extents.y, confined_center_global.y + room_half_extents.y)

		# Daña a Isaac al tocarlo, con un intervalo.
		if global_position.distance_to(player.global_position) < contact_range:
			if contact_cooldown <= 0.0:
				if player.has_method("take_damage"):
					print("¡El enemigo golpeó a Isaac!")
					player.take_damage(contact_damage)
					contact_cooldown = 1.0
				else:
					print("ERROR: Isaac no tiene la función take_damage()")

	_update_animation()
	_animate_body(delta)

# ---------------------------------------------------------------
# ANIMACIÓN
# ---------------------------------------------------------------

func _update_animation() -> void:
	if sprite == null or sprite.sprite_frames == null or is_dead:
		return

	var anim := "mover"
	if velocity.length() < 1.0 and sprite.sprite_frames.has_animation("idle"):
		anim = "idle"

	if sprite.sprite_frames.has_animation(anim) and sprite.animation != anim:
		sprite.play(anim)
	elif not sprite.is_playing() and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

	# Mira hacia donde se mueve
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0

func _animate_body(delta: float) -> void:
	# Respiración y balanceo para sprites de un solo cuadro (por ejemplo, Srbos).
	if sprite == null or is_dead:
		return
	if pulse_amount <= 0.0 and bob_amount <= 0.0:
		return
	var moving := velocity.length() > 1.0
	anim_time += delta * (4.0 if moving else 2.2)
	var wave := sin(anim_time)
	sprite.position.y = wave * bob_amount
	# No tocamos la escala mientras el aplastamiento por daño está en curso
	if pulse_amount > 0.0 and (squash_tween == null or not squash_tween.is_running()):
		sprite.scale = base_scale * Vector2(1.0 + wave * pulse_amount, 1.0 - wave * pulse_amount)

func _play_hurt_squash() -> void:
	if sprite == null:
		return
	# Aplastamiento que rebota a su tamaño normal
	if squash_tween != null and squash_tween.is_running():
		squash_tween.kill()
	sprite.scale = base_scale * Vector2(1.3, 0.7)
	squash_tween = create_tween()
	squash_tween.tween_property(sprite, "scale", base_scale, 0.2).set_trans(Tween.TRANS_BACK)

func _die() -> void:
	is_dead = true
	remove_from_group("enemies") # Isaac ya no lo puede golpear de nuevo
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Sin colisión mientras se desvanece
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)

	# Igual que antes: marcar el sector como despejado al derrotar al minijefe
	if boss_display_name != "" and sector_type != "":
		GameData.mark_sector_cleared(sector_type)
		print("Sector despejado: ", sector_type, " (minijefe derrotado: ", boss_display_name, ")")

	queue_redraw()

	if sprite == null:
		queue_free()
		return

	# Se aplasta y se desvanece antes de borrarse
	if squash_tween != null and squash_tween.is_running():
		squash_tween.kill()
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "scale", base_scale * Vector2(1.4, 0.1), 0.25)
	t.tween_property(sprite, "modulate:a", 0.0, 0.25)
	t.chain().tween_callback(queue_free)

# ---------------------------------------------------------------
# DAÑO
# ---------------------------------------------------------------

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= amount
	queue_redraw()

	# Usamos attacker_position para calcular la dirección del empuje
	if attacker_position != Vector2.ZERO:
		var knockback_dir := (global_position - attacker_position).normalized()
		global_position += knockback_dir * 18.0

	_spawn_hit_sparks(global_position)

	modulate = Color(2.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)

	if health <= 0:
		_die()
	else:
		_play_hurt_squash()

func _draw() -> void:
	if is_dead:
		return

	# Silueta antigua del minijefe: solo si no hay AnimatedSprite2D en la escena.
	if boss_display_name != "" and sprite == null:
		draw_circle(Vector2(0, 2), 25.0, Color("#49243f"))
		draw_circle(Vector2(0, -1), 20.0, Color("#9d477d"))
		draw_rect(Rect2(-17, -8, 7, 7), Color("#f8d8f0"))
		draw_rect(Rect2(10, -8, 7, 7), Color("#f8d8f0"))
		draw_line(Vector2(-7, 10), Vector2(7, 10), Color("#54213d"), 3.0)

	# Nombre del minijefe sobre su barra de vida
	if boss_display_name != "":
		var label_y := minf(-38.0, bar_offset_y - 10.0)
		draw_string(ThemeDB.fallback_font, Vector2(-100, label_y), "MINIJEFE: " + boss_display_name, HORIZONTAL_ALIGNMENT_CENTER, 200, 13, Color("#ffe29a"))

	# Barra de vida sobre el enemigo.
	draw_rect(
		Rect2(-bar_width / 2.0, bar_offset_y, bar_width, 4),
		Color("#421c27")
	)

	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	draw_rect(
		Rect2(-bar_width / 2.0, bar_offset_y, bar_width * ratio, 4),
		Color("#e74c3c")
	)

func _spawn_hit_sparks(hit_position: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 12
	particles.lifetime = 0.25
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color("#e8c879") # Color dorado/chispa

	if hit_position != Vector2.ZERO:
		particles.global_position = hit_position
	else:
		particles.global_position = global_position

	get_parent().add_child(particles)

	# Eliminar las partículas al terminar. El temporizador se conecta a las
	# partículas (no a este enemigo), así funciona aunque el enemigo muera
	# en ese mismo golpe.
	get_tree().create_timer(0.3).timeout.connect(particles.queue_free)
