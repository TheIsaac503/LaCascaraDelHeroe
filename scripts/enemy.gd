
extends CharacterBody2D

@export var speed: float = 65.0
@export var max_health: int = 40
@export var contact_damage: int = 10

var health: int
var player: CharacterBody2D
var contact_cooldown: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	queue_redraw()

func _physics_process(delta: float) -> void:
	contact_cooldown = maxf(0.0, contact_cooldown - delta)

	if not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player = players[0] as CharacterBody2D

	if is_instance_valid(player):
		var direction := global_position.direction_to(
			player.global_position
		)
		velocity = direction * speed
		move_and_slide()

		# Daña a Isaac al tocarlo, con un intervalo.
		if global_position.distance_to(player.global_position) < 35.0:
			if contact_cooldown <= 0.0:
				if player.has_method("take_damage"):
					print("¡El enemigo golpeó a Isaac!")
					player.take_damage(contact_damage)
					contact_cooldown = 1.0
				else:
					print("ERROR: Isaac no tiene la función take_damage()")

func take_damage(amount: int) -> void:
	health -= amount
	health = maxi(health, 0)
	queue_redraw()

	if health <= 0:
		queue_free()

func _draw() -> void:
	# Cuerpo provisional del enemigo.
	draw_circle(Vector2.ZERO, 12.0, Color("#a43d65"))
	draw_circle(Vector2(-4, -3), 2.0, Color.WHITE)
	draw_circle(Vector2(4, -3), 2.0, Color.WHITE)

	# Barra de vida sobre el enemigo.
	draw_rect(
		Rect2(-15, -23, 30, 4),
		Color("#421c27")
	)

	var ratio := float(health) / float(max_health)
	draw_rect(
		Rect2(-15, -23, 30.0 * ratio, 4),
		Color("#e74c3c")
	)
