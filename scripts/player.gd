extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)

@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_range: float = 48.0
@export var speed: float = 180.0
var final_resurrection_speed_multiplier: float = 1.0
var final_resurrection_cooldown_multiplier: float = 1.0

var health: int = 100
var attack_cooldown: float = 0.0
var base_attack_cooldown: float = 0.35
var sfx_player: AudioStreamPlayer2D

# Ahora el personaje usa AnimatedSprite2D (antes era Sprite2D).
# Animaciones esperadas en su SpriteFrames:
#   idle_frente, idle_espalda, idle_izquierda, idle_derecha,
#   caminar, ataque (sin loop), dano (sin loop), muerte (sin loop)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Dirección hacia la que mira Isaac.
var facing: Vector2 = Vector2.DOWN

# Estados de animación.
var is_attacking := false
var is_hurt := false
var is_dead := false

# --- DASH / ESQUIVA ---
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.25
@export var dash_cooldown: float = 0.8
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.DOWN

# --- VARIABLES DE HABILIDADES PASIVAS ---
var pride_bonus_damage := 0.0
var pride_timer := 0.0
var love_timer := 0.0
var brotherhood_shield_ready := true
var brotherhood_shield_timer := 0.0
var skill_cooldowns: Dictionary = {}
var empowered_next_attack := false
var honor_invulnerable_timer := 0.0
var bondad_attack_bonus := 0.0
var last_damage_time := 0.0
# --- CURACIÓN FUERA DE COMBATE ---
var healing_wait_timer: float = 0.0
var healing_interval_timer: float = 0.0
var healing_started: bool = false

# Pociones y efectos temporales
var speed_potion_timer: float = 0.0
var speed_potion_multiplier: float = 1.0
var potion_label: Label

func _ready() -> void:
	add_to_group("player")
	apply_soul_fragment()
	health = max_health
	health_changed.emit(health, max_health)

	# Inicializamos el reproductor de audio
	sfx_player = AudioStreamPlayer2D.new()
	add_child(sfx_player)

	# Para saber cuándo terminan las animaciones de ataque y daño
	sprite.animation_finished.connect(_on_animation_finished)
	_play(_idle_name())
	_build_potion_hud()

	var bar := get_tree().get_first_node_in_group("player_health_bar")
	if bar is ProgressBar:
		health_changed.connect(
			func(current: int, maximum: int) -> void:
				bar.max_value = maximum
				bar.value = current
		)
		bar.max_value = max_health
		bar.value = health

func _physics_process(delta: float) -> void:
	# Cooldowns
	if speed_potion_timer > 0.0:
		speed_potion_timer = maxf(0.0, speed_potion_timer - delta)
		if speed_potion_timer <= 0.0:
			speed_potion_multiplier = 1.0
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		move_and_slide()
		if dash_timer <= 0.0:
			is_dashing = false
			velocity = Vector2.ZERO
		_update_animation(dash_direction)
		queue_redraw()
		return

	# Lógica de las habilidades pasivas con el tiempo
	_process_soul_passives(delta)
	_process_ability_timers(delta)
	
	# Curación automática fuera de combate
	_process_out_of_combat_healing(delta)

	# Movimiento del personaje
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		facing = direction

	velocity = direction * speed * speed_potion_multiplier
	move_and_slide()

	_update_animation(direction)
	queue_redraw()
	_update_potion_hud()

func _build_potion_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	potion_label = Label.new()
	potion_label.position = Vector2(20, 70)
	potion_label.add_theme_font_size_override("font_size", 18)
	potion_label.add_theme_color_override("font_color", Color("#f0e7d1"))
	layer.add_child(potion_label)
	_update_potion_hud()

func _update_potion_hud() -> void:
	if is_instance_valid(potion_label):
		potion_label.text = "❤️ x%d [1]   ⚡ x%d [2]" % [int(GameData.potions.get("heal", 0)), int(GameData.potions.get("speed", 0))]

# ---------------------------------------------------------------
# ANIMACIONES
# ---------------------------------------------------------------

func _update_animation(direction: Vector2) -> void:
	if is_dead or is_attacking or is_hurt:
		return
	if direction != Vector2.ZERO:
		# Los frames de caminar miran a la derecha; se voltean hacia la izquierda.
		# Si se ve al revés, cambia a: facing.x > 0.0
		sprite.flip_h = facing.x < 0.0
		_play("caminar")
	else:
		sprite.flip_h = false
		_play(_idle_name())

func _idle_name() -> String:
	if absf(facing.x) > absf(facing.y):
		return "idle_derecha" if facing.x > 0.0 else "idle_izquierda"
	return "idle_espalda" if facing.y < 0.0 else "idle_frente"

func _play(anim: String) -> void:
	# Las poses idle de la hoja vienen al doble de tamaño que los frames de animación
	sprite.scale = Vector2.ONE * (0.5 if anim.begins_with("idle") else 1.0)
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)

func _on_animation_finished() -> void:
	match sprite.animation:
		"ataque":
			is_attacking = false
		"dano":
			is_hurt = false

# ---------------------------------------------------------------
# HABILIDADES PASIVAS
# ---------------------------------------------------------------

func _process_soul_passives(delta: float) -> void:
	# Los beneficios se acumulan según los fragmentos que Isaac haya recuperado.
	if GameData.has_fragment("Amor"):
		love_timer += delta
		if love_timer >= 3.0:
			love_timer = 0.0
			if health < max_health:
				health = mini(health + 10, max_health)
				health_changed.emit(health, max_health)

	if GameData.has_fragment("Orgullo"):
		pride_timer += delta
		if pride_timer >= 6.0 and Time.get_ticks_msec() / 1000.0 - last_damage_time >= 6.0:
			pride_timer = 0.0
			pride_bonus_damage = minf(pride_bonus_damage + 0.4, 4.0)

	if GameData.has_fragment("Hermandad") and not brotherhood_shield_ready:
		brotherhood_shield_timer += delta
		if brotherhood_shield_timer >= 10.0:
			brotherhood_shield_timer = 0.0
			brotherhood_shield_ready = true
			_flash_shield()

func _process_ability_timers(delta: float) -> void:
	for fragment in skill_cooldowns.keys():
		skill_cooldowns[fragment] = maxf(0.0, float(skill_cooldowns[fragment]) - delta)
	if honor_invulnerable_timer > 0.0:
		honor_invulnerable_timer = maxf(0.0, honor_invulnerable_timer - delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		start_dash()
		return
	if event.is_action_pressed("attack"):
		attack()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			use_equipped_ability(0)
		elif event.keycode == KEY_R:
			use_equipped_ability(1)
		elif event.keycode == KEY_1:
			use_potion("heal")
		elif event.keycode == KEY_2:
			use_potion("speed")

func use_potion(kind: String) -> void:
	if is_dead or not GameData.consume_potion(kind):
		return
	if kind == "heal":
		health = mini(max_health, health + maxi(20, int(max_health * 0.35)))
		health_changed.emit(health, max_health)
		_show_ability_message("POCION DE CURACION")
	elif kind == "speed":
		speed_potion_multiplier = 1.45
		speed_potion_timer = 8.0
		_show_ability_message("VELOCIDAD +")

func start_dash() -> void:
	if is_dead or is_dashing or is_attacking or is_hurt:
		return
	if dash_cooldown_timer > 0.0:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = facing
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	dash_direction = direction.normalized()
	facing = dash_direction
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity = dash_direction * dash_speed
	_play("caminar")

func use_equipped_ability(slot: int) -> void:
	if slot < 0 or slot >= GameData.equipped_abilities.size():
		return
	var fragment := str(GameData.equipped_abilities[slot])
	if fragment.is_empty() or not GameData.has_fragment(fragment) or is_dead:
		return
	if float(skill_cooldowns.get(fragment, 0.0)) > 0.0:
		return
	var cooldown := 12.0
	match fragment:
		"Ira":
			_damage_nearby_enemies(125.0, int(attack_damage * 2.0))
			cooldown = 14.0
		"Bondad":
			health = mini(max_health, health + int(round(max_health * 0.25)))
			health_changed.emit(health, max_health)
			cooldown = 20.0
		"Orgullo":
			empowered_next_attack = true
			cooldown = 16.0
			_show_ability_message("SIGUIENTE GOLPE POTENCIADO")
		"Honor":
			honor_invulnerable_timer = 3.0
			modulate = Color(1.0, 0.85, 0.45)
			var honor_tween := create_tween()
			honor_tween.tween_property(self, "modulate", Color.WHITE, 3.0)
			cooldown = 18.0
		"Hermandad":
			brotherhood_shield_ready = true
			brotherhood_shield_timer = 0.0
			_flash_shield()
			cooldown = 22.0
		"Creatividad":
			_damage_nearby_enemies(210.0, int(attack_damage * 1.5))
			cooldown = 17.0
		"Amor":
			health = max_health
			health_changed.emit(health, max_health)
			cooldown = 30.0
	skill_cooldowns[fragment] = cooldown

func _damage_nearby_enemies(radius: float, damage: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is Node2D and global_position.distance_to(enemy.global_position) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, global_position)

func _show_ability_message(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color("#ffe29a"))
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(-100, -75)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", -110.0, 1.0)
	tween.tween_callback(label.queue_free)

func _flash_shield() -> void:
	# Parpadeo azul brillante al activarse o recargarse el escudo de Hermandad
	modulate = Color(0.3, 0.6, 1.8)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)

func _draw() -> void:
	# Isaac usa un AnimatedSprite2D con sprites PNG de pixel art.
	pass

# ---------------------------------------------------------------
# COMBATE
# ---------------------------------------------------------------

func attack() -> void:
	if attack_cooldown > 0.0 or is_dead or is_dashing:
		return

	play_attack_sfx()
	attack_cooldown = base_attack_cooldown

	# Animación de ataque
	is_attacking = true
	is_hurt = false
	sprite.scale = Vector2.ONE
	sprite.flip_h = facing.x < 0.0
	sprite.play("ataque")

	var damage_multiplier := 1.0
	if GameData.has_fragment("Ira"):
		damage_multiplier += 0.15
		if health <= max_health * 0.5:
			damage_multiplier += 0.10
	if GameData.has_fragment("Orgullo"):
		damage_multiplier += 0.10
	if GameData.has_fragment("Creatividad"):
		damage_multiplier += 0.10
	var total_damage := int((attack_damage + pride_bonus_damage) * damage_multiplier)
	if empowered_next_attack:
		total_damage *= 2
		empowered_next_attack = false

	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue

		var offset: Vector2 = node.global_position - global_position
		var distance := offset.length()

		if distance > attack_range or distance == 0.0:
			continue

		var direction_to_enemy := offset.normalized()

		if facing.normalized().dot(direction_to_enemy) >= 0.35:
			if node.has_method("take_damage"):
				node.take_damage(total_damage, global_position)
				_spawn_hit_effect(node.global_position)

func _spawn_hit_effect(pos: Vector2) -> void:
	var fx := Sprite2D.new()
	fx.texture = preload("res://assets/rewards/effects (new)/hit_effect_anim_f0.png")
	fx.global_position = pos
	fx.scale = Vector2(2, 2)
	get_tree().current_scene.add_child(fx)
	var tween := create_tween()
	tween.tween_property(fx, "scale", Vector2(3, 3), 0.12)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, 0.18)
	tween.tween_callback(fx.queue_free)

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_dashing:
		return
		
	if honor_invulnerable_timer > 0.0:
		return
	# Hermandad absorbe un golpe y se recarga tras 10 segundos.
	if GameData.has_fragment("Hermandad") and brotherhood_shield_ready:
		brotherhood_shield_ready = false
		brotherhood_shield_timer = 0.0
		_flash_shield()
		return
	if GameData.has_fragment("Honor"):
		amount = maxi(1, int(round(amount * 0.85)))
	last_damage_time = Time.get_ticks_msec() / 1000.0
		
	play_hurt_sfx()
	# Reiniciar la curación al recibir daño
	healing_wait_timer = 0.0
	healing_interval_timer = 0.0
	healing_started = false
	
	health -= amount
	health = clampi(health, 0, max_health)
	health_changed.emit(health, max_health)

	# Si te golpean, se reinicia el bono acumulado de Orgullo
	if GameData.has_fragment("Orgullo"):
		pride_bonus_damage = 0.0
		pride_timer = 0.0

	# Knockback
	if attacker_position != Vector2.ZERO:
		var knockback_dir := (global_position - attacker_position).normalized()
		velocity = knockback_dir * 250.0
		move_and_slide()

	_flash_red()

	if health <= 0:
		die()
	else:
		# Animación de daño
		is_attacking = false
		is_hurt = true
		sprite.scale = Vector2.ONE
		sprite.play("dano")

func _flash_red() -> void:
	modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func _on_attack_button_pressed() -> void:
	attack()

func apply_soul_fragment() -> void:
	max_health = 100
	attack_damage = 20
	base_attack_cooldown = 0.35
	speed = 180.0
	pride_bonus_damage = 0.0

	# La elección inicial ya está registrada como fragmento poseído.
	if GameData.has_fragment("Bondad"):
		max_health += 10
	if GameData.has_fragment("Hermandad"):
		max_health += 10
	if GameData.has_fragment("Honor"):
		attack_damage += 2
	if GameData.has_fragment("Creatividad"):
		attack_damage += 2
	if GameData.has_fragment("Amor"):
		speed += 5.0

func apply_new_fragment(fragment_name: String) -> void:
	# Los aumentos de atributos se aplican una sola vez al recuperar cada alma.
	match fragment_name:
		"Bondad", "Hermandad":
			max_health += 10
			health += 10
			health_changed.emit(health, max_health)
		"Honor", "Creatividad":
			attack_damage += 2
		"Amor":
			speed += 5.0

func die() -> void:
	# La protección secreta de Amy solo funciona en el combate final y una vez.
	if GameData.final_battle_active and GameData.amy_spared and not GameData.amy_extra_life_used:
		GameData.amy_extra_life_used = true
		is_dead = false
		is_attacking = false
		is_hurt = true
		health = maxi(1, int(round(max_health * 0.5)))
		attack_damage = maxi(1, int(round(attack_damage * 1.5)))
		final_resurrection_speed_multiplier = 1.5
		final_resurrection_cooldown_multiplier = 1.0 / 1.5
		speed *= 1.5
		base_attack_cooldown /= 1.5
		attack_cooldown = 0.0
		set_physics_process(true)
		set_process_input(true)
		sprite.scale = Vector2.ONE
		sprite.play("dano")
		health_changed.emit(health, max_health)
		var revive_tween := create_tween()
		modulate = Color(1.0, 0.55, 1.0)
		revive_tween.tween_property(self, "modulate", Color.WHITE, 1.0)
		return

	is_dead = true
	is_dashing = false
	is_attacking = false
	is_hurt = false
	health = 0
	health_changed.emit(health, max_health)
	set_physics_process(false)
	set_process_input(false)

	# Animación de muerte (antes se llamaba hide() directamente)
	sprite.scale = Vector2.ONE
	sprite.flip_h = facing.x < 0.0
	sprite.play("muerte")
	# Si necesitas que desaparezca después de la animación, descomenta:
	# await get_tree().create_timer(1.0).timeout
	# hide()

# ---------------------------------------------------------------
# SONIDOS
# ---------------------------------------------------------------

func play_attack_sfx() -> void:
	if sfx_player == null:
		return
	var sample_rate := 44100.0
	var duration := 0.08
	var num_samples := int(sample_rate * duration)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = int(sample_rate)

	var data := PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / sample_rate
		var freq := 800.0 - (t * 6000.0)
		var sample := int(sin(t * freq) * 127.0 * (1.0 - (t / duration)))
		data[i] = clampi(sample + 128, 0, 255)

	stream.data = data
	sfx_player.stream = stream
	sfx_player.play()

func play_hurt_sfx() -> void:
	if sfx_player == null:
		return
	var sample_rate := 44100.0
	var duration := 0.12
	var num_samples := int(sample_rate * duration)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = int(sample_rate)

	var data := PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / sample_rate
		var freq := 300.0 - (t * 2000.0)
		var sample := int(sin(t * freq) * 127.0 * (1.0 - (t / duration)))
		data[i] = clampi(sample + 128, 0, 255)

	stream.data = data
	sfx_player.stream = stream
	sfx_player.play()

func _process_out_of_combat_healing(delta: float) -> void:
	# No curar a Isaac si está muerto
	if is_dead or health <= 0:
		return

	# El fragmento Amor conserva su propia curación
	if GameData.has_fragment("Amor"):
		healing_wait_timer = 0.0
		healing_interval_timer = 0.0
		healing_started = false
		return

	# Si Isaac ya tiene toda la vida, no necesita curarse
	if health >= max_health:
		healing_wait_timer = 0.0
		healing_interval_timer = 0.0
		healing_started = false
		return

	# Esperar 3 segundos sin recibir daño
	if not healing_started:
		healing_wait_timer += delta

		if healing_wait_timer >= 3.0:
			healing_started = true
			healing_interval_timer = 0.0

		return

	# Recuperar 4 puntos de vida cada 1 segundos
	healing_interval_timer += delta

	if healing_interval_timer >= 1.0:
		healing_interval_timer = 0.0
		health = mini(health + 5, max_health)
		health_changed.emit(health, max_health)
