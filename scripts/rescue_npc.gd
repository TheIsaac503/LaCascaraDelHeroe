extends Node2D

@export var npc_name: String = "Prisionero"
var rescued := false
var prompt: Label
var player: Node2D

func _ready() -> void:
    add_to_group("rescue_npcs")
    player = get_tree().get_first_node_in_group("player") as Node2D
    prompt = Label.new()
    prompt.text = "E: rescatar"
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.position = Vector2(-65, -48)
    prompt.size = Vector2(130, 24)
    prompt.add_theme_font_size_override("font_size", 12)
    prompt.add_theme_color_override("font_color", Color("#fff0b8"))
    prompt.visible = false
    add_child(prompt)
    queue_redraw()

func _process(_delta: float) -> void:
    if rescued:
        return
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node2D
    prompt.visible = is_instance_valid(player) and player.global_position.distance_to(global_position) < 75.0

func _unhandled_input(event: InputEvent) -> void:
    if rescued or not event.is_action_pressed("interact"):
        return
    if is_instance_valid(player) and player.global_position.distance_to(global_position) < 75.0:
        rescued = true
        GameData.rescued_npcs += 1
        print("NPC rescatado: ", npc_name, ". Total: ", GameData.rescued_npcs)
        queue_free()

func _draw() -> void:
    draw_circle(Vector2(0, 10), 12, Color(0.05, 0.05, 0.05, 0.35))
    draw_circle(Vector2(0, -5), 7, Color("#edbd91"))
    draw_rect(Rect2(-8, 2, 16, 22), Color("#b7a1d6"))
    draw_line(Vector2(-5, 20), Vector2(-8, 30), Color("#24202b"), 4.0)
    draw_line(Vector2(5, 20), Vector2(8, 30), Color("#24202b"), 4.0)
