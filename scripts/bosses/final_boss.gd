extends CombatantBase
class_name FinalBoss

signal phase_changed(phase_number: int, phase_title: String)
signal dialogue_line(speaker: String, message: String)
signal battle_finished

@export var movement_speed := 82.0
@export var minimum_separation: float = 46.0
@export var room_half_extents := Vector2(500.0, 260.0)
@export var daynan_damage := 20
@export var darkness_damage := 18
@export var fusion_damage := 26

var player: CharacterBody2D
var phase := 1
var state: StringName = &"intro"
var state_timer := 2.0
var attack_index := 0
var target_position := Vector2.ZERO
var warning_line: Line2D
var dialogue_label: Label
var phase_label: Label
var health_bar: ProgressBar
var _dialogue_queue: Array[Dictionary] = []
var _dialogue_timer := 0.0
var _battle_over := false
var sprite: AnimatedSprite2D
var facing_direction := Vector2.DOWN

func _ready() -> void:
	max_health = 900
	super._ready()
	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_play_idle()
	_create_battle_ui()
	_say("La Oscuridad", "Por fin has llegado, Isaac. ¿De verdad creíste que recuperarías lo que perdiste?")
	state = &"intro"
	state_timer = 3.0
	phase_changed.emit(1, "Daynan, el héroe corrompido")

func _create_battle_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FinalBossHUD"
	# La escena aún puede estar construyendo sus hijos durante _ready().
	# Diferimos únicamente la incorporación del HUD a current_scene.
	get_tree().current_scene.add_child.call_deferred(layer)
	health_bar = ProgressBar.new()
	health_bar.name = "FinalBossHealth"
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.anchor_left = 0.2
	health_bar.anchor_right = 0.8
	health_bar.anchor_top = 0.035
	health_bar.anchor_bottom = 0.035
	health_bar.offset_bottom = 18
	layer.add_child(health_bar)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.anchor_left = 0.2
	phase_label.anchor_right = 0.8
	phase_label.anchor_top = 0.07
	phase_label.anchor_bottom = 0.07
	phase_label.text = "FASE 1 — DAYNAN CORROMPIDO"
	layer.add_child(phase_label)
	dialogue_label = Label.new()
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.anchor_left = 0.12
	dialogue_label.anchor_right = 0.88
	dialogue_label.anchor_top = 0.78
	dialogue_label.anchor_bottom = 0.94
	dialogue_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(dialogue_label)

func _play_anim(anim: StringName) -> void:
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)

func _play_idle() -> void:
	if facing_direction.y < -0.5:
		_play_anim(&"idle_espalda")
	elif facing_direction.x > 0.5:
		_play_anim(&"idle_derecha")
	elif facing_direction.x < -0.5:
		_play_anim(&"idle_izquierda")
	else:
		_play_anim(&"idle_frente")

func _update_visual() -> void:
	if is_dead:
		return
	if state == &"windup" or state == &"recover":
		return
	if velocity.length() > 1.0:
		_play_anim(&"caminar")
	else:
		_play_idle()

func _physics_process(delta: float) -> void:
	if is_dead or _battle_over:
		return
	if not is_instance_valid(player):
		var found := get_tree().get_first_node_in_group("player")
		if found is CharacterBody2D:
			player = found
	_process_dialogue(delta)
	if not is_instance_valid(player):
		return
	state_timer -= delta
	match state:
		&"intro":
			velocity = Vector2.ZERO
			if state_timer <= 0.0:
				_say("Daynan", "Isaac... aléjate... no puedo controlarlo...")
				state = &"idle"
				state_timer = 1.1
		&"transition":
			velocity = Vector2.ZERO
			if state_timer <= 0.0:
				_begin_phase(phase + 1)
		&"windup":
			velocity = Vector2.ZERO
			if state_timer <= 0.0:
				_execute_attack()
				state = &"idle"
				state_timer = _cooldown_for_phase()
				_clear_warning()
		&"idle":
			_move_toward_player(delta)
			if state_timer <= 0.0:
				_start_attack()
		&"recover":
			velocity = Vector2.ZERO
			if state_timer <= 0.0:
				state = &"idle"
				state_timer = 0.35
	move_and_slide()
	_clamp_to_arena()
	_update_visual()

func _move_toward_player(_delta: float) -> void:
	var offset := player.global_position - global_position
	var desired := 95.0 if phase == 1 else (135.0 if phase == 2 else 115.0)
	if offset.length() > 0.001:
		facing_direction = offset.normalized()
	if offset.length() > desired:
		velocity = offset.normalized() * movement_speed * (1.0 if phase == 1 else 1.18)
	else:
		velocity = Vector2.ZERO

func _start_attack() -> void:
	var attack_anim: StringName = [&"ataque1", &"ataque2", &"ataque3"][attack_index % 3]
	_play_anim(attack_anim)
	state = &"windup"
	target_position = player.global_position
	state_timer = 0.75 if phase == 1 else (0.62 if phase == 2 else 0.48)
	_show_warning()

func _show_warning() -> void:
	_clear_warning()
	warning_line = Line2D.new()
	warning_line.width = 5.0
	warning_line.default_color = Color(0.85, 0.25, 0.95, 0.85) if phase >= 2 else Color(0.95, 0.35, 0.25, 0.9)
	warning_line.z_index = 30
	var points := PackedVector2Array()
	var direction := (target_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	if phase == 1:
		points.append(Vector2(-room_half_extents.x, target_position.y - global_position.y))
		points.append(Vector2(room_half_extents.x, target_position.y - global_position.y))
	elif phase == 2:
		points.append(direction * 18.0)
		points.append(direction * 260.0)
	else:
		for i in range(33):
			var angle := TAU * float(i) / 32.0
			points.append(Vector2(cos(angle), sin(angle)) * 150.0)
	warning_line.points = points
	add_child(warning_line)

func _execute_attack() -> void:
	if not is_instance_valid(player):
		return
	var offset := player.global_position - global_position
	if phase == 1:
		match attack_index % 3:
			0: # Corte lateral corrupto
				if absf(player.global_position.y - target_position.y) < 34.0 and absf(offset.x) < 245.0:
					_damage_player(daynan_damage)
			1: # Corte de ruptura
				if absf(player.global_position.x - target_position.x) < 34.0 and absf(offset.y) < 190.0:
					_damage_player(daynan_damage + 3)
			2: # Danza de espadas
				if offset.length() < 125.0:
					_damage_player(daynan_damage + 5)
	elif phase == 2:
		match attack_index % 3:
			0: # Lanzas del vacío: línea vertical marcada
				if absf(player.global_position.x - target_position.x) < 48.0 and absf(offset.y) < 230.0:
					_damage_player(darkness_damage + 4)
			1: # Prisión de sombras: zona alrededor del objetivo
				if player.global_position.distance_to(target_position) < 100.0:
					_damage_player(darkness_damage)
			2: # Succión del alma
				if offset.length() < 190.0:
					player.velocity += -offset.normalized() * 180.0
					_damage_player(darkness_damage + 2)
	else:
		match attack_index % 3:
			0: # Juicio final
				if absf(player.global_position.y - target_position.y) < 45.0 and absf(offset.x) < 280.0:
					_damage_player(fusion_damage)
			1: # Ruptura del alma
				if offset.length() < 175.0:
					_damage_player(fusion_damage + 4)
			2: # Persecución imparable
				var charge_direction := (target_position - global_position).normalized()
				global_position += charge_direction * 115.0
				if player.global_position.distance_to(global_position) < 75.0:
					_damage_player(fusion_damage + 6)
	attack_index += 1
	state = &"recover"
	state_timer = 0.45

func _damage_player(amount: int) -> void:
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(amount, global_position)

func _cooldown_for_phase() -> float:
	return 1.0 if phase == 1 else (0.78 if phase == 2 else 0.58)

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or _battle_over:
		return
	_play_anim(&"dano")
	super.take_damage(amount, attacker_position)
	if is_instance_valid(health_bar):
		health_bar.value = health
	if is_dead:
		_finish_battle()
		return
	if phase == 1 and health <= 585:
		_transition_to_phase_two()
	elif phase == 2 and health <= 315:
		_transition_to_phase_three()

func _transition_to_phase_two() -> void:
	phase = 2
	state = &"transition"
	state_timer = 3.0
	velocity = Vector2.ZERO
	_clear_warning()
	_say("La Oscuridad", "¡Tu compañero ya no tiene fuerzas para resistirse!")
	_say("Daynan", "¡Isaac... no dejes que termine así!")
	_say("La Oscuridad", "¡CÁLLATE! ¡TU CUERPO ME PERTENECE!")
	phase_changed.emit(2, "La Oscuridad despierta")
	_update_phase_label("FASE 2 — LA OSCURIDAD")
	modulate = Color(0.72, 0.48, 1.0)

func _transition_to_phase_three() -> void:
	phase = 3
	state = &"transition"
	state_timer = 4.0
	velocity = Vector2.ZERO
	_clear_warning()
	_say("Daynan", "¡AÚN... NO... HE... TERMINADO!")
	_say("La Oscuridad", "Entonces desaparecerás conmigo.")
	_say("Daynan", "¡ISAAC! ¡TERMINA ESTO!")
	phase_changed.emit(3, "La fusión definitiva")
	_update_phase_label("FASE 3 — LA FUSIÓN DEFINITIVA")
	modulate = Color(0.62, 0.25, 0.82)
	movement_speed = 112.0

func _begin_phase(new_phase: int) -> void:
	phase = new_phase
	attack_index = 0
	state = &"idle"
	state_timer = 0.8
	if phase == 2:
		_say("La Oscuridad", "¡Ahora conocerás el verdadero vacío!")
	elif phase == 3:
		_say("La Oscuridad", "¡Somos uno! ¡No puedes separarnos!")

func _update_phase_label(value: String) -> void:
	if is_instance_valid(phase_label):
		phase_label.text = value

func _say(speaker: String, message: String) -> void:
	_dialogue_queue.append({"speaker": speaker, "message": message})
	if _dialogue_timer <= 0.0:
		_show_next_dialogue()

func _show_next_dialogue() -> void:
	if _dialogue_queue.is_empty():
		if is_instance_valid(dialogue_label):
			dialogue_label.text = ""
		_dialogue_timer = 0.0
		return
	var line: Dictionary = _dialogue_queue.pop_front()
	if is_instance_valid(dialogue_label):
		dialogue_label.text = str(line.speaker) + ": " + str(line.message)
	dialogue_line.emit(str(line.speaker), str(line.message))
	_dialogue_timer = 2.6

func _process_dialogue(delta: float) -> void:
	if _dialogue_timer <= 0.0:
		return
	_dialogue_timer -= delta
	if _dialogue_timer <= 0.0:
		_show_next_dialogue()

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, -room_half_extents.x, room_half_extents.x)
	global_position.y = clampf(global_position.y, -room_half_extents.y, room_half_extents.y)

func _clear_warning() -> void:
	if is_instance_valid(warning_line):
		warning_line.queue_free()
	warning_line = null

func _finish_battle() -> void:
	if _battle_over:
		return
	_battle_over = true
	GameData.final_battle_active = false
	GameData.final_battle_completed = true
	_clear_warning()
	if is_instance_valid(dialogue_label):
		dialogue_label.text = "Daynan: Gracias... por no rendirte conmigo, hermano."
	battle_finished.emit()
	var victory := Label.new()
	victory.text = "LA OSCURIDAD HA SIDO DERROTADA\nLa cáscara ya no te define."
	victory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory.anchor_left = 0.15
	victory.anchor_right = 0.85
	victory.anchor_top = 0.38
	victory.anchor_bottom = 0.62
	victory.add_theme_font_size_override("font_size", 28)
	var layer := get_tree().current_scene.get_node_or_null("FinalBossHUD")
	if layer is CanvasLayer:
		layer.add_child(victory)
		var return_button := Button.new()
		return_button.text = "VOLVER AL MENÚ PRINCIPAL"
		return_button.anchor_left = 0.35
		return_button.anchor_right = 0.65
		return_button.anchor_top = 0.68
		return_button.anchor_bottom = 0.68
		return_button.offset_top = 0.0
		return_button.offset_bottom = 44.0
		layer.add_child(return_button)
		return_button.pressed.connect(_return_to_main_menu)

func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _defeat() -> void:
	# Mantener al jefe visible para la secuencia de victoria.
	_play_anim(&"muerte")
	is_dead = true
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	set_physics_process(false)
	_disable_collisions()
	defeated.emit()
