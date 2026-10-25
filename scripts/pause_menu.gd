
extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

var pause_overlay: ColorRect
var pause_panel: VBoxContainer
var is_paused := false


func _ready() -> void:
	# Permite que el menú funcione incluso cuando el juego está pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_pause_menu()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	is_paused = true
	pause_overlay.visible = true
	get_tree().paused = true


func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	pause_overlay.visible = false


func _create_pause_menu() -> void:
	# Fondo oscuro que cubre toda la pantalla.
	pause_overlay = ColorRect.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.color = Color(0.03, 0.02, 0.06, 0.88)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	add_child(pause_overlay)

	# Centrar el panel.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)

	pause_panel = VBoxContainer.new()
	pause_panel.custom_minimum_size = Vector2(420, 0)
	pause_panel.add_theme_constant_override("separation", 16)
	center.add_child(pause_panel)

	# Título.
	var title := Label.new()
	title.text = "JUEGO EN PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#e8c879"))
	pause_panel.add_child(title)

	# Botón continuar.
	var continue_button := _create_button("CONTINUAR")
	pause_panel.add_child(continue_button)
	continue_button.pressed.connect(resume_game)

	# Botón volver al menú.
	var menu_button := _create_button("VOLVER AL MENÚ")
	pause_panel.add_child(menu_button)
	menu_button.pressed.connect(_return_to_menu)

	# Botón salir.
	var exit_button := _create_button("SALIR DEL JUEGO")
	pause_panel.add_child(exit_button)
	exit_button.pressed.connect(_exit_game)


func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 60)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL

	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#f2e8d5"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#30233f")
	normal.border_color = Color("#80649a")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#49325d")
	hover.border_color = Color("#e8c879")

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)

	return button


func _return_to_menu() -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _exit_game() -> void:
	get_tree().quit()
