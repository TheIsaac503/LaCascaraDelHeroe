extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

var pause_overlay: ColorRect
var pause_panel: VBoxContainer
var is_paused := false

# Pantalla de Game Over
var game_over_overlay: ColorRect

# Elementos del HUD de juego
var health_bar: ProgressBar
var health_label: Label
var soul_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var old_soul_label := get_node_or_null("SoulLabel")
	if old_soul_label:
		old_soul_label.queue_free()
		
	_build_game_hud()
	_create_pause_menu()
	_create_game_over_menu()
	update_soul_label()
	
	call_deferred("_connect_to_player")

func _unhandled_key_input(event: InputEvent) -> void:
	if is_paused or (game_over_overlay and game_over_overlay.visible):
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()

func _connect_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(update_health)
		if "health" in player and "max_health" in player:
			update_health(player.health, player.max_health)

func _build_game_hud() -> void:
	var top_bar := MarginContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.add_theme_constant_override("margin_left", 20)
	top_bar.add_theme_constant_override("margin_right", 20)
	top_bar.add_theme_constant_override("margin_top", 15)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)
	
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(hbox)
	
	# --- SECCIÓN VIDA (Izquierda) ---
	var health_container := VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 4)
	hbox.add_child(health_container)
	
	var hp_title := Label.new()
	hp_title.text = "VIDA DE ISAAC"
	hp_title.add_theme_font_size_override("font_size", 12)
	hp_title.add_theme_color_override("font_color", Color("#b9a9cb"))
	health_container.add_child(hp_title)
	
	var bar_container := PanelContainer.new()
	bar_container.custom_minimum_size = Vector2(240, 24)
	
	var empty_style := StyleBoxEmpty.new()
	bar_container.add_theme_stylebox_override("panel", empty_style)
	health_container.add_child(bar_container)
	
	health_bar = ProgressBar.new()
	health_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_bar.show_percentage = false
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#170f1e")
	bg_style.border_color = Color("#594168")
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(4)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#b8253b")
	fill_style.border_color = Color("#e8c879")
	fill_style.set_border_width_all(1)
	fill_style.set_corner_radius_all(4)
	
	health_bar.add_theme_stylebox_override("background", bg_style)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	bar_container.add_child(health_bar)
	
	health_label = Label.new()
	health_label.text = "100 / 100"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", Color("#ffffff"))
	bar_container.add_child(health_label)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# --- SECCIÓN ALMA (Derecha) ---
	var soul_box := PanelContainer.new()
	var soul_style := StyleBoxFlat.new()
	soul_style.bg_color = Color("#21152f")
	soul_style.border_color = Color("#e8c879")
	soul_style.set_border_width_all(2)
	soul_style.set_corner_radius_all(6)
	soul_style.content_margin_left = 16
	soul_style.content_margin_right = 16
	soul_style.content_margin_top = 8
	soul_style.content_margin_bottom = 8
	soul_box.add_theme_stylebox_override("panel", soul_style)
	hbox.add_child(soul_box)
	
	soul_label = Label.new()
	soul_label.name = "SoulLabel"
	soul_label.text = "ALMA: DESCONOCIDA"
	soul_label.add_theme_font_size_override("font_size", 16)
	soul_label.add_theme_color_override("font_color", Color("#e8c879"))
	soul_box.add_child(soul_label)

func update_health(current: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current
	if health_label:
		health_label.text = str(current) + " / " + str(max_hp)
		
	# Si la vida llega a 0, activar Game Over
	if current <= 0:
		show_game_over()

func update_soul_label() -> void:
	if soul_label == null:
		return
	var fragment := str(GameData.selected_fragment)
	if fragment.is_empty():
		fragment = "SIN ELEGIR"
	soul_label.text = "ALMA: " + fragment.to_upper()

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
	pause_overlay = ColorRect.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.color = Color(0.03, 0.02, 0.06, 0.88)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	add_child(pause_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)

	pause_panel = VBoxContainer.new()
	pause_panel.custom_minimum_size = Vector2(420, 0)
	pause_panel.add_theme_constant_override("separation", 16)
	center.add_child(pause_panel)

	var title := Label.new()
	title.text = "JUEGO EN PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#e8c879"))
	pause_panel.add_child(title)

	var continue_button := _create_button("CONTINUAR")
	pause_panel.add_child(continue_button)
	continue_button.pressed.connect(resume_game)

	var menu_button := _create_button("VOLVER AL MENÚ")
	pause_panel.add_child(menu_button)
	menu_button.pressed.connect(_return_to_menu)

	var exit_button := _create_button("SALIR DEL JUEGO")
	pause_panel.add_child(exit_button)
	exit_button.pressed.connect(_exit_game)

func _create_game_over_menu() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.name = "GameOverOverlay"
	game_over_overlay.color = Color(0.12, 0.02, 0.04, 0.92)
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.visible = false
	add_child(game_over_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.add_child(center)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_constant_override("separation", 16)
	center.add_child(panel)

	var title := Label.new()
	title.text = "HAS CAÍDO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#b8253b"))
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "El fragmento de tu alma se ha extinguido en la oscuridad."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#b9a9cb"))
	panel.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer)

	var retry_button := _create_button("REINTENTAR")
	panel.add_child(retry_button)
	retry_button.pressed.connect(_retry_game)

	var menu_button := _create_button("MENÚ PRINCIPAL")
	panel.add_child(menu_button)
	menu_button.pressed.connect(_return_to_menu)

func show_game_over() -> void:
	get_tree().paused = true
	if game_over_overlay:
		game_over_overlay.visible = true

func _retry_game() -> void:
	get_tree().paused = false
	# Reiniciamos directamente a la selección de fragmentos para volver a intentar
	get_tree().change_scene_to_file("res://scenes/ui/SoulSelection.tscn")

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
