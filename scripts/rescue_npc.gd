extends Node2D

@export var npc_name: String = "Prisionero"
@export var npc_style: String = ""
var rescued := false
var prompt: Label
var player: Node2D
var sprite: Sprite2D
var shadow: Sprite2D
var bob_time := 0.0

const NPC_TEXTURES := {
    "mercader": preload("res://assets/sprites/npcs/mercader.png"),
    "guardia": preload("res://assets/sprites/npcs/guardia.png"),
    "anciano": preload("res://assets/sprites/npcs/anciano.png"),
    "aldeano": preload("res://assets/sprites/npcs/aldeano.png")
}

func _ready() -> void:
    add_to_group("rescue_npcs")
    player = get_tree().get_first_node_in_group("player") as Node2D
    _create_visual()
    prompt = Label.new()
    prompt.text = "E: rescatar"
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.position = Vector2(-65, -78)
    prompt.size = Vector2(130, 24)
    prompt.add_theme_font_size_override("font_size", 12)
    prompt.add_theme_color_override("font_color", Color("#fff0b8"))
    prompt.visible = false
    add_child(prompt)

func _pick_style() -> String:
    if npc_style != "" and NPC_TEXTURES.has(npc_style):
        return npc_style
    var styles := ["aldeano", "anciano", "guardia", "mercader"]
    return styles[abs(npc_name.hash()) % styles.size()]

func _create_visual() -> void:
    shadow = Sprite2D.new()
    shadow.texture = null
    shadow.position = Vector2(0, 26)
    add_child(shadow)
    sprite = Sprite2D.new()
    sprite.texture = NPC_TEXTURES[_pick_style()]
    sprite.scale = Vector2(0.42, 0.42)
    sprite.position = Vector2(0, -4)
    sprite.z_index = 2
    add_child(sprite)

func _process(delta: float) -> void:
    if rescued:
        return
    bob_time += delta
    if sprite != null:
        sprite.position.y = -4.0 + sin(bob_time * 2.0) * 1.5
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node2D
    prompt.visible = is_instance_valid(player) and player.global_position.distance_to(global_position) < 75.0
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if rescued or not event.is_action_pressed("interact"):
        return
    if is_instance_valid(player) and player.global_position.distance_to(global_position) < 75.0:
        rescued = true
        GameData.rescued_npcs += 1
        print("NPC rescatado: ", npc_name, ". Total: ", GameData.rescued_npcs)
        queue_free()

func _draw() -> void:
    _draw_npc_ellipse(Vector2(0, 27), Vector2(18, 6), Color(0.03, 0.03, 0.04, 0.35))

func _draw_npc_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(17):
        var angle := TAU * float(i) / 16.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
