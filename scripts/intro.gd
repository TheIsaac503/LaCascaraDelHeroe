extends Control

var dialogue_index: int = 0
var dialogues: Array[String] = [
    "Isaac y Daynan eran dos heroes destinados a vencer a la Oscuridad.",
    "Cuando la batalla final estaba por comenzar, un hechizo de luz los tomo por sorpresa.",
    "Isaac cayo inconsciente. Antes de perder el conocimiento, escucho una voz: «Intenta ser el mismo». ",
    "Despierta con dolor en una celda fria. No recuerda como llego alli y apenas puede distinguir una voz al otro lado de los barrotes."
]

var dialogue_label: Label
var next_button: Button

func _ready() -> void:
    GameData.reset_game()
    _build_interface()
    _show_dialogue()

func _build_interface() -> void:
    var background := ColorRect.new()
    background.color = Color("#171c2b")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation", 24)
    layout.add_theme_constant_override("margin_left", 32)
    layout.add_theme_constant_override("margin_right", 32)
    layout.add_theme_constant_override("margin_top", 40)
    layout.add_theme_constant_override("margin_bottom", 40)
    add_child(layout)

    var title := Label.new()
    title.text = "LA CASCARA DEL HEROE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    layout.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Prologo: El alma dividida"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    layout.add_child(subtitle)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(spacer)

    dialogue_label = Label.new()
    dialogue_label.custom_minimum_size = Vector2(0, 150)
    dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    dialogue_label.add_theme_font_size_override("font_size", 21)
    layout.add_child(dialogue_label)

    var bottom_spacer := Control.new()
    bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(bottom_spacer)

    next_button = Button.new()
    next_button.text = "Continuar"
    next_button.custom_minimum_size = Vector2(0, 55)
    next_button.pressed.connect(_on_next_pressed)
    layout.add_child(next_button)

func _show_dialogue() -> void:
    dialogue_label.text = dialogues[dialogue_index]
    if dialogue_index == dialogues.size() - 1:
        next_button.text = "Despertar en el calabozo"

func _on_next_pressed() -> void:
    if dialogue_index < dialogues.size() - 1:
        dialogue_index += 1
        _show_dialogue()
    else:
        get_tree().change_scene_to_file("res://scenes/ui/SoulSelection.tscn")
