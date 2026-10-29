extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/Isaac.tscn")
const NPC_SCRIPT := preload("res://scripts/rescue_npc.gd")
const ROOM_SIZE := Vector2(640, 400)

var player: Node2D
var status_label: Label
var exit_position := Vector2(255, 20)

func _ready() -> void:
    player = get_node_or_null("Isaac") as Node2D
    if player == null:
        player = PLAYER_SCENE.instantiate()
        player.name = "Isaac"
        add_child(player)
    player.position = Vector2(-225, 35)
    _build_walls()
    _add_prisoner()
    _build_hud()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-ROOM_SIZE.x / 2.0, -ROOM_SIZE.y / 2.0, ROOM_SIZE.x, ROOM_SIZE.y), Color("#292d38"))
    # Losas de piedra.
    for x_step in range(1, 8):
        var x := -ROOM_SIZE.x / 2.0 + float(x_step) * ROOM_SIZE.x / 8.0
        draw_line(Vector2(x, -ROOM_SIZE.y / 2.0 + 18), Vector2(x, ROOM_SIZE.y / 2.0 - 18), Color("#414653"), 2.0)
    for y_step in range(1, 5):
        var y := -ROOM_SIZE.y / 2.0 + float(y_step) * ROOM_SIZE.y / 5.0
        draw_line(Vector2(-ROOM_SIZE.x / 2.0 + 18, y), Vector2(ROOM_SIZE.x / 2.0 - 18, y), Color("#414653"), 2.0)
    # Muros gruesos y rejas de la celda inicial.
    draw_rect(Rect2(-320, -200, 640, 24), Color("#151820"))
    draw_rect(Rect2(-320, 176, 640, 24), Color("#151820"))
    draw_rect(Rect2(-320, -200, 24, 400), Color("#151820"))
    draw_rect(Rect2(296, -200, 24, 400), Color("#151820"))
    draw_rect(Rect2(-285, -95, 110, 8), Color("#171a22"))
    for bar_x in range(-280, -175, 17):
        draw_rect(Rect2(float(bar_x), -95, 5, 95), Color("#8a929f"))
    draw_rect(Rect2(225, -40, 70, 110), Color("#171a22"))
    draw_rect(Rect2(238, -28, 44, 86), Color("#795c3c"))
    draw_circle(Vector2(270, 15), 4, Color("#e6c36f"))
    draw_string(ThemeDB.fallback_font, Vector2(-300, -150), "CALABOZO 01", HORIZONTAL_ALIGNMENT_LEFT, 200, 16, Color("#d0c4a6"))
    draw_string(ThemeDB.fallback_font, Vector2(180, 105), "SALIDA", HORIZONTAL_ALIGNMENT_CENTER, 100, 13, Color("#e6c36f"))
    # Antorcha.
    draw_rect(Rect2(-280, -145, 8, 24), Color("#76543a"))
    draw_circle(Vector2(-276, -150), 8, Color("#e98d45"))
    draw_circle(Vector2(-276, -150), 4, Color("#ffe6a1"))

func _build_walls() -> void:
    _add_wall(Vector2(0, -190), Vector2(640, 20))
    _add_wall(Vector2(0, 190), Vector2(640, 20))
    _add_wall(Vector2(-310, 0), Vector2(20, 400))
    _add_wall(Vector2(310, 0), Vector2(20, 400))

func _add_wall(wall_position: Vector2, wall_size: Vector2) -> void:
    var body := StaticBody2D.new()
    body.position = wall_position
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = wall_size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

func _add_prisoner() -> void:
    var npc := Node2D.new()
    npc.name = "PrisioneroInicial"
    npc.set_script(NPC_SCRIPT)
    npc.set("npc_name", "Prisionero del calabozo")
    npc.position = Vector2(-55, -25)
    add_child(npc)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    status_label = Label.new()
    status_label.text = "MUEVETE: WASD o flechas   |   ATACAR: ESPACIO / CLIC   |   E: interactuar"
    status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    status_label.offset_left = 20
    status_label.offset_top = 16
    status_label.offset_right = -20
    status_label.offset_bottom = 48
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.add_theme_color_override("font_color", Color("#f0e7d1"))
    layer.add_child(status_label)

func _process(_delta: float) -> void:
    if is_instance_valid(player) and player.global_position.distance_to(to_global(exit_position)) < 70.0:
        status_label.text = "Presiona E para salir del calabozo e ir a tu sector"
    else:
        status_label.text = "Explora el calabozo | WASD/flechas: moverte | Espacio/clic: atacar | E: salir"

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact") and is_instance_valid(player):
        if player.global_position.distance_to(to_global(exit_position)) < 70.0:
            GameData.intro_completed = true
            get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
