extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)

@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_range: float = 48.0
@export var speed: float = 180.0

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

# --- VARIABLES DE HABILIDADES PASIVAS ---
var pride_bonus_damage := 0.0
var pride_timer := 0.0
var love_timer := 0.0
var brotherhood_shield_ready := true
var honor_counter_damage := 0.0
# --- CURACIÓN FUERA DE COMBATE ---
var healing_wait_timer: float = 0.0
var healing_interval_timer: float = 0.0
var healing_started: bool = false

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
	# Cooldown de ataque
	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	# Lógica de las habilidades pasivas con el tiempo
	_process_soul_passives(delta)
	
	# Curación automática fuera de combate
	_process_out_of_combat_healing(delta)

	# Movimiento del personaje
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		facing = direction

	velocity = direction * speed
	move_and_slide()

	_update_animation(direction)
	queue_redraw()

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
	match GameData.selected_fragment:
		"Amor":
			# 1. AMOR: Regenera 2 de vida cada 3 segundos
			love_timer += delta
			if love_timer >= 3.0:
				love_timer = 0.0
				if health < max_health:
					health = mini(health + 5, max_health)
					health_changed.emit(health, max_health)

		"Orgullo":
			# 2. ORGULLO: Sube +2 de daño cada 4 segundos sin recibir daño
			pride_timer += delta
			if pride_timer >= 4.0:
				pride_timer = 0.0
				pride_bonus_damage = mini(pride_bonus_damage + 2.0, 20.0)

		"Ira":
			# 3. IRA: Si la vida cae a menos del 50%, entra en estado de frenesí
			if health < (max_health / 2):
				base_attack_cooldown = 0.15
				speed = 210.0
			else:
				base_attack_cooldown = 0.22
				speed = 180.0

		"Hermandad":
			# 4. HERMANDAD: Tanque resistente que recupera su escudo si pasa 10s sin recibir daño
			if not brotherhood_shield_ready:
				love_timer += delta # Reutilizamos el temporizador para la recarga del escudo
				if love_timer >= 5.0:
					love_timer = 0.0
					brotherhood_shield_ready = true
					_flash_shield()

		"Honor":
			# 5. HONOR: Incrementa la velocidad de movimiento mientras mantengas la vida completa
			if health == max_health:
				speed = 205.0
			else:
				speed = 180.0

		"Creatividad":
			# 6. CREATIVIDAD: Su daño cambia aleatoriamente en cada ataque (se procesa al atacar)
			pass

		"Bondad":
			# 7. BONDAD: Recupera vida al derrotar enemigos mediante los orbes (se procesa en enemy.gd)
			pass

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()

func attack() -> void:
	if attack_cooldown > 0.0 or is_dead:
		return

	play_attack_sfx()
	attack_cooldown = base_attack_cooldown

	# Animación de ataque
	is_attacking = true
	is_hurt = false
	sprite.scale = Vector2.ONE
	sprite.flip_h = facing.x < 0.0
	sprite.play("ataque")

	var total_damage := int(attack_damage + pride_bonus_damage)

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

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
		
	# Escudo de Hermandad: bloquea un golpe
	if GameData.selected_fragment == "Hermandad" and brotherhood_shield_ready:
		brotherhood_shield_ready = false
		_flash_shield()
		return
		
	play_hurt_sfx()
	# Reiniciar la curación al recibir daño
	healing_wait_timer = 0.0
	healing_interval_timer = 0.0
	healing_started = false
	
	health -= amount
	health = clampi(health, 0, max_health)
	health_changed.emit(health, max_health)

	# Si te golpean, se reinicia el bono acumulado de Orgullo
	if GameData.selected_fragment == "Orgullo":
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

	match GameData.selected_fragment:
		"Ira":
			base_attack_cooldown = 0.20
		"Bondad":
			max_health = 120
		"Orgullo":
			attack_damage = 22
		"Honor":
			max_health = 120
			attack_damage = 24
		"Hermandad":
			max_health = 130
		"Creatividad":
			attack_damage = 30
		"Amor":
			max_health = 100
			speed = 190.0

func die() -> void:
	is_dead = true
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
	if GameData.selected_fragment == "Amor":
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

	# Esperar 5 segundos sin recibir daño
	if not healing_started:
		healing_wait_timer += delta

		if healing_wait_timer >= 5.0:
			healing_started = true
			healing_interval_timer = 0.0

		return

	# Recuperar 4 puntos de vida cada 2 segundos
	healing_interval_timer += delta

	if healing_interval_timer >= 2.0:
		healing_interval_timer = 0.0
		health = mini(health + 4, max_health)
		health_changed.emit(health, max_health)
