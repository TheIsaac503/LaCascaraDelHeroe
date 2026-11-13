extends Control

const STORY_IMAGES: Array[Texture2D] = [
	preload("res://assets/story/heroes.png"),
	preload("res://assets/story/spell.png"),
	preload("res://assets/story/unconscious.png"),
	preload("res://assets/story/dungeon.png"),
	preload("res://assets/story/mysterious_voice.png"),
	preload("res://assets/story/fragments.png"),
	preload("res://assets/story/communication_cut.png")
]

var dialogue_index: int = 0
var dialogues: Array[String] = [
	"Isaac y Daynan eran dos héroes destinados a vencer a la oscuridad.",
	"Justo cuando la batalla final estaba por comenzar, un hechizo de luz los tomó desprevenidos y los impactó.",
	"Isaac cayó inconsciente. Antes de perder el conocimiento, alcanzó a escuchar unas palabras: «Intenta ser el mismo».",
	"Luego de aquello, Isaac despertó en un calabozo con un extraño sentimiento: algo dentro de él ya no estaba bien.",
	"Una voz femenina desconocida rompió el silencio: «Oh, querido héroe... tu alma ha sido dividida y enviada a diferentes sectores».",
	"«Solo pude lograr que conservaras un fragmento. Elige con cuidado cuál te acompañará primero».",
	"«Lamento no poder ayudarte más, pero estoy fuera de mi dominio. Buscaré la forma de ayu...». La comunicación se cortó."
]

var dialogue_label: Label
var next_button: Button
var story_image: TextureRect

func _ready() -> void:
	GameData.reset_game()
	_build_interface()
	_show_dialogue()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#080a12")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 55)
	margin.add_theme_constant_override("margin_right", 55)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "LA CÁSCARA DEL HÉROE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 38)
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("#ead7ff"))
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Prólogo: El alma dividida"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.custom_minimum_size = Vector2(0, 28)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("#cbb8dc"))
	layout.add_child(subtitle)

	var image_frame := PanelContainer.new()
	image_frame.custom_minimum_size = Vector2(0, 360)
	image_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("#0c0e18")
	frame_style.border_color = Color("#5f5072")
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(6)
	image_frame.add_theme_stylebox_override("panel", frame_style)
	layout.add_child(image_frame)

	story_image = TextureRect.new()
	story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	story_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_frame.add_child(story_image)

	var dialogue_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.03, 0.08, 0.92)
	panel_style.border_color = Color("#8d6ca8")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	dialogue_panel.custom_minimum_size = Vector2(0, 104)
	layout.add_child(dialogue_panel)

	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_font_size_override("font_size", 19)
	dialogue_label.add_theme_color_override("font_color", Color("#f0e8d8"))
	dialogue_panel.add_child(dialogue_label)

	next_button = Button.new()
	next_button.text = "Continuar"
	next_button.custom_minimum_size = Vector2(0, 48)
	next_button.add_theme_font_size_override("font_size", 18)
	next_button.pressed.connect(_on_next_pressed)
	layout.add_child(next_button)

func _show_dialogue() -> void:
	dialogue_label.text = dialogues[dialogue_index]
	story_image.texture = STORY_IMAGES[dialogue_index]
	story_image.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(story_image, "modulate:a", 1.0, 0.20)
	next_button.text = "Elegir fragmento" if dialogue_index == dialogues.size() - 1 else "Continuar"

func _on_next_pressed() -> void:
	if dialogue_index < dialogues.size() - 1:
		dialogue_index += 1
		_show_dialogue()
	else:
		get_tree().change_scene_to_file("res://scenes/ui/SoulSelection.tscn")
