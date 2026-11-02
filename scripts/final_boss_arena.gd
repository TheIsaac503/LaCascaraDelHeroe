extends Node2D

const ARENA_SIZE := Vector2(1120.0, 560.0)

var player_health_bar: ProgressBar
var player_health_label: Label

func _ready() -> void:
	GameData.final_battle_active = true
	GameData.final_battle_completed = false
	queue_redraw()
	_restore_player_after_scene_load.call_deferred()
	_create_player_hud()

func _restore_player_after_scene_load() -> void:
	var player := get_node_or_null("Isaac")
	if player == null:
		return
	if not GameData.final_entry_stats.is_empty():
		for property_name in GameData.final_entry_stats.keys():
			player.set(property_name, GameData.final_entry_stats[property_name])
		if player.has_signal("health_changed"):
			player.health_changed.emit(player.health, player.max_health)
	GameData.final_entry_stats.clear()

func _create_player_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "FinalPlayerHUD"
	add_child(layer)
	player_health_label = Label.new()
	player_health_label.text = "ISAAC"
	player_health_label.position = Vector2(28, 22)
	player_health_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(player_health_label)
	player_health_bar = ProgressBar.new()
	player_health_bar.name = "IsaacHealth"
	player_health_bar.position = Vector2(28, 48)
	player_health_bar.size = Vector2(260, 20)
	player_health_bar.show_percentage = false
	layer.add_child(player_health_bar)
	var player := get_node_or_null("Isaac")
	if player != null and player.has_signal("health_changed"):
		player.health_changed.connect(_update_player_health)
		_update_player_health(player.health, player.max_health)

func _update_player_health(current: int, maximum: int) -> void:
	if not is_instance_valid(player_health_bar):
		return
	player_health_bar.max_value = maximum
	player_health_bar.value = current
	if is_instance_valid(player_health_label):
		player_health_label.text = "ISAAC  %d / %d" % [current, maximum]

func _draw() -> void:
	draw_rect(Rect2(-ARENA_SIZE / 2.0, ARENA_SIZE), Color("#171321"), true)
	draw_rect(Rect2(-ARENA_SIZE / 2.0 + Vector2(18, 18), ARENA_SIZE - Vector2(36, 36)), Color("#272039"), false, 8.0)
	for i in range(8):
		var x := -440.0 + float(i) * 125.0
		draw_line(Vector2(x, -250), Vector2(x + 55, 250), Color(0.45, 0.28, 0.58, 0.13), 3.0)
	draw_circle(Vector2.ZERO, 95.0, Color(0.35, 0.12, 0.48, 0.18))
