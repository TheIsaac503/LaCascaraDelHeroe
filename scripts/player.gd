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

# Dirección hacia la que mira Isaac.
var facing: Vector2 = Vector2.DOWN

# --- VARIABLES DE HABILIDADES PASIVAS ---
var pride_bonus_damage := 0.0
var pride_timer := 0.0
var love_timer := 0.0
var brotherhood_shield_ready := true
var honor_counter_damage := 0.0

func _ready() -> void:
	add_to_group("player")
	apply_soul_fragment()
	health = max_health
	health_changed.emit(health, max_health)
	
	# Inicializamos el reproductor de audio
	sfx_player = AudioStreamPlayer2D.new()
	add_child(sfx_player)

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

	# Movimiento del personaje
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		facing = direction

	velocity = direction * speed
	move_and_slide()

	queue_redraw()

func _process_soul_passives(delta: float) -> void:
	match GameData.selected_fragment:
		"Amor":
			# 1. AMOR: Regenera 2 de vida cada 3 segundos
			love_timer += delta
			if love_timer >= 3.0:
				love_timer = 0.0
				if health < max_health:
					health = mini(health + 2, max_health)
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
				if love_timer >= 10.0:
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
	# Sombra
	draw_circle(Vector2(0, 10), 10, Color(0.05, 0.05, 0.05, 0.45))

	# Cuerpo: túnica azul
	draw_rect(Rect2(-9, -8, 18, 19), Color("#3267b2"))

	# Cabeza
	draw_circle(Vector2(0, -12), 7, Color("#edbd91"))

	# Cabello
	draw_rect(Rect2(-7, -19, 14, 5), Color("#493126"))

	# Espada provisional
	var sword_start := facing * 9.0
	var sword_end := facing * 22.0
	draw_line(sword_start, sword_end, Color("#e5e8ee"), 4.0)

	# Empuñadura
	draw_line(sword_start - Vector2(3, 3), sword_start + Vector2(3, 3), Color("#8b552d"), 3.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()

func attack() -> void:
	if attack_cooldown > 0.0:
		return

	play_attack_sfx()
	attack_cooldown = base_attack_cooldown

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
	play_hurt_sfx()
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
	health = 0
	health_changed.emit(health, max_health)
	set_physics_process(false)
	hide()

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
