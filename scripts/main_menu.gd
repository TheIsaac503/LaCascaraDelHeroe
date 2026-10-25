
extends Control

const INTRO_SCENE := "res://scenes/ui/Intro.tscn"

var controls_dialog: AcceptDialog


func _ready() -> void:
	# Fondo oscuro
	var background := ColorRect.new()
	background.color = Color("#100d19")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# Brillo violeta decorativo
	var glow := ColorRect.new()
	glow.color = Color("#21152f")
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# Panel que centra el contenido
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(480, 0)
	menu.add_theme_constant_override("separation", 18)
	center.add_child(menu)

	# Título
	var title := Label.new()
	title.text = "LA CÁSCARA\nDEL HÉROE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#e8c879"))
	title.add_theme_color_override("font_shadow_color", Color("#000000"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	menu.add_child(title)

	# Subtítulo
	var subtitle := Label.new()
	subtitle.text = "Tu alma está dividida. Tu destino comienza aquí."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#b9a9cb"))
	menu.add_child(subtitle)

	# Separación visual
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	menu.add_child(spacer)

	# Botones
	var new_game := _create_button("NUEVA PARTIDA")
	menu.add_child(new_game)
	new_game.pressed.connect(_start_game)

	var controls := _create_button("CONTROLES")
	menu.add_child(controls)
	controls.pressed.connect(_show_controls)

	var exit_button := _create_button("SALIR DEL JUEGO")
	menu.add_child(exit_button)
	exit_button.pressed.connect(_exit_game)

	# Texto inferior
	var footer := Label.new()
	footer.text = "UNA AVENTURA ENTRE LUZ Y OSCURIDAD"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color("#80748e"))
	menu.add_child(footer)

	# Ventana de controles
	controls_dialog = AcceptDialog.new()
	controls_dialog.title = "Controles de Isaac"
	controls_dialog.dialog_text = "MOVERSE: WASD o flechas\nATACAR: ESPACIO\nPAUSAR: ESC (lo conectaremos después)"
	add_child(controls_dialog)


func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 62)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL

	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color("#f2e8d5"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("#e8c879"))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#30233f")
	normal.border_color = Color("#80649a")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#49325d")
	hover.border_color = Color("#e8c879")

	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color("#1d1428")

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover)

	return button


func _start_game() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)


func _show_controls() -> void:
	controls_dialog.popup_centered()


func _exit_game() -> void:
	get_tree().quit()
