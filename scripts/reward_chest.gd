extends Area2D

@export var min_potions := 2
@export var max_potions := 3
var opened := false
var player_near := false
var sprite: Sprite2D
var prompt: Label

const CLOSED := preload("res://assets/rewards/props_itens/chest_closed_anim_f0.png")
const OPEN := preload("res://assets/rewards/props_itens/chest_open.png")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite = Sprite2D.new()
	sprite.texture = CLOSED
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	add_child(collision)
	prompt = Label.new()
	prompt.text = "E: abrir cofre"
	prompt.position = Vector2(-45, -40)
	prompt.visible = false
	prompt.add_theme_font_size_override("font_size", 14)
	add_child(prompt)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		prompt.visible = not opened

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not opened and player_near and event.is_action_pressed("interact"):
		_open()

func _open() -> void:
	opened = true
	prompt.visible = false
	sprite.texture = OPEN
	var count := randi_range(min_potions, max_potions)
	for i in count:
		var kind := "heal" if randf() < 0.6 else "speed"
		GameData.add_potion(kind, 1)
	_show_message("+%d pociones" % count)

func _show_message(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.position = Vector2(-45, -60)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", -95.0, 1.2)
	tween.tween_callback(label.queue_free)
