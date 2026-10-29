extends Area2D

@export var source_sector: String = "Ira"
var _used := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 30.0, Color(0.25, 0.8, 1.0, 0.18))
	draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 48, Color(0.35, 0.9, 1.0), 4.0)
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 48, Color(0.75, 0.95, 1.0), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-44, 48), "PORTAL", HORIZONTAL_ALIGNMENT_CENTER, 88, 12, Color(0.75, 0.95, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	var destinations: Array[String] = []
	for fragment_variant in GameData.sector_positions.keys():
		var fragment := str(fragment_variant)
		if fragment != source_sector and not GameData.cleared_sectors.has(fragment):
			destinations.append(fragment)
	if destinations.is_empty():
		print("No hay sectores sin despejar disponibles para el portal.")
		return
	destinations.shuffle()
	var destination: String = destinations[0]
	_used = true
	var destination_position: Vector2 = GameData.sector_positions[destination]
	body.global_position = destination_position
	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO
	print("Portal desde ", source_sector, " hacia sala 1 de ", destination)
	await get_tree().create_timer(0.5).timeout
	_used = false
