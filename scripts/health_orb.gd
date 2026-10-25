extends Area2D

var heal_amount := 15

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if "health" in body and "max_health" in body:
			body.health = mini(body.health + heal_amount, body.max_health)
			body.health_changed.emit(body.health, body.max_health)
			queue_free()
