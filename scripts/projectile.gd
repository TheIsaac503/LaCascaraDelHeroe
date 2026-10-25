extends Area2D

var speed := 220.0
var direction := Vector2.ZERO
var damage := 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	elif not body.is_in_group("enemies"):
		# Se destruye si choca contra paredes
		queue_free()
