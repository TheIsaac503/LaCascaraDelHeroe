
extends CharacterBody2D
signal health_changed(current_health: int, maximum_health: int)

@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_range: float = 48.0

var health: int = 100
var attack_cooldown: float = 0.0
# Velocidad de movimiento en píxeles por segundo.
@export var speed: float = 180.0

# Dirección hacia la que mira Isaac.
var facing: Vector2 = Vector2.DOWN

func _ready() -> void:
	queue_redraw()
	apply_soul_fragment()
	health = max_health
	add_to_group("player")
	health_changed.emit(health, max_health)

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
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	# Lee las acciones configuradas en Input Map.
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	# Actualiza la dirección del personaje.
	if direction != Vector2.ZERO:
		facing = direction

	# Movimiento con colisiones.
	velocity = direction * speed
	move_and_slide()

	queue_redraw()

func _draw() -> void:
	# Sombra de Isaac.
	draw_circle(
	Vector2(0, 10),
	10,
	Color(0.05, 0.05, 0.05, 0.45)
)

	# Cuerpo: túnica azul.
	draw_rect(
		Rect2(-9, -8, 18, 19),
		Color("#3267b2")
	)

	# Cabeza.
	draw_circle(
		Vector2(0, -12),
		7,
		Color("#edbd91")
	)

	# Cabello.
	draw_rect(
		Rect2(-7, -19, 14, 5),
		Color("#493126")
	)

	# Espada provisional en la dirección de mirada.
	var sword_start := facing * 9.0
	var sword_end := facing * 22.0

	draw_line(
		sword_start,
		sword_end,
		Color("#e5e8ee"),
		4.0
	)

	# Empuñadura.
	draw_line(
		sword_start - Vector2(3, 3),
		sword_start + Vector2(3, 3),
		Color("#8b552d"),
		3.0
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()

func attack() -> void:
	if attack_cooldown > 0.0:
		return

	attack_cooldown = 0.35

	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue

		var offset: Vector2 = node.global_position - global_position
		var distance := offset.length()

		if distance > attack_range or distance == 0.0:
			continue

		# Golpea principalmente hacia donde mira Isaac.
		var direction_to_enemy := offset.normalized()

		if facing.normalized().dot(direction_to_enemy) >= 0.35:
			if node.has_method("take_damage"):
				node.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)

	if health <= 0:
		# Reinicio provisional para poder seguir probando.
		health = max_health
		global_position = Vector2.ZERO
		health_changed.emit(health, max_health)


func _on_attack_button_pressed() -> void:
	attack() # Replace with function body.
	
	
func apply_soul_fragment() -> void:
	# Estadisticas iniciales.
	max_health = 100
	attack_damage = 20
	attack_cooldown = 0.35
	speed = 180.0

	match GameData.selected_fragment:
		"Ira":
			attack_cooldown = 0.25

		"Bondad":
			max_health = 120

		"Orgullo":
			attack_damage = 24

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
	health = max_health
	health_changed.emit(health, max_health)
