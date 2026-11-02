extends Area2D

@export var speed: float = 250.0
@export var damage: int = 10

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return

	rotation = direction.angle()
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

		queue_free()
