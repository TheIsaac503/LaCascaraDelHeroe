extends Control

const INTRO_SCENE := "res://scenes/ui/Intro.tscn"
const MENU_IMAGE: Texture2D = preload("res://assets/story/menu.png")

var controls_dialog: AcceptDialog

func _ready() -> void:
	var background_image := TextureRect.new()
	background_image.texture = MENU_IMAGE
	background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_image)

	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.03, 0.10, 0.30)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 260.0
	center.offset_right = -260.0
	add_child(center)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(430, 0)
	menu.add_theme_constant_override("separation", 14)
	center.add_child(menu)

	var title := Label.new()
	title.text = "LA CÁSCARA DEL HÉROE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#f3e4ff"))
	title.add_theme_color_override("font_shadow_color", Color("#000000"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	menu.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Tu alma está dividida. Tu destino comienza aquí."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#e0d2ef"))
	menu.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	menu.add_child(spacer)

	var new_game := _create_button("NUEVA PARTIDA")
	menu.add_child(new_game)
	new_game.pressed.connect(_start_game)

	var controls := _create_button("CONTROLES")
	menu.add_child(controls)
	controls.pressed.connect(_show_controls)

	var exit_button := _create_button("SALIR DEL JUEGO")
	menu.add_child(exit_button)
	exit_button.pressed.connect(_exit_game)

	var footer := Label.new()
	footer.text = "UNA AVENTURA ENTRE LUZ Y OSCURIDAD"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color("#c2afcf"))
	menu.add_child(footer)

	controls_dialog = AcceptDialog.new()
	controls_dialog.title = "Controles de Isaac"
	controls_dialog.dialog_text = "MOVERSE: WASD o flechas\nATACAR: ESPACIO\nESQUIVAR: CLIC DERECHO\nPAUSAR: ESC"
	add_child(controls_dialog)

func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#f2e8d5"))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.08, 0.20, 0.88)
	normal.border_color = Color("#9c75c9")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.25, 0.16, 0.36, 0.94)
	hover.border_color = Color("#f1d47d")

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", hover)
	return button

func _start_game() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)

func _show_controls() -> void:
	controls_dialog.popup_centered()

func _exit_game() -> void:
	get_tree().quit()
