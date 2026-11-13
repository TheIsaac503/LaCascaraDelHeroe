extends Node2D

const ARENA_SIZE := Vector2(1100, 540)

func _ready() -> void:
	queue_redraw()
	_create_thematic_props()

func _draw() -> void:
	# Arena final: mezcla de las temáticas de los siete sectores, corrompida por la batalla final.
	draw_rect(Rect2(-ARENA_SIZE / 2.0, ARENA_SIZE), Color("#201c2a"))
	var colors := [Color("#4b2928"), Color("#294638"), Color("#44364e"), Color("#344457"), Color("#39464a"), Color("#3c3b55"), Color("#563b50")]
	for i in range(7):
		var x := -550.0 + float(i) * (1100.0 / 7.0)
		draw_rect(Rect2(x, -270, 1100.0 / 7.0, 540), colors[i].darkened(0.35))
	for x in range(-520, 521, 40):
		draw_line(Vector2(x, -240), Vector2(x, 240), Color(1,1,1,0.05), 1.0)
	for y in range(-240, 241, 40):
		draw_line(Vector2(-520, y), Vector2(520, y), Color(1,1,1,0.05), 1.0)
	draw_rect(Rect2(-550, -270, 1100, 540), Color("#0d0b12"), false, 12.0)
	draw_string(ThemeDB.fallback_font, Vector2(-150, -225), "EL ÚLTIMO HÉROE", HORIZONTAL_ALIGNMENT_CENTER, 300, 22, Color("#e8d9b0"))

func _create_thematic_props() -> void:
	for x in [-500.0, -330.0, -160.0, 10.0, 180.0, 350.0, 500.0]:
		var mark := Polygon2D.new()
		mark.polygon = PackedVector2Array([Vector2(-8,0), Vector2(0,-14), Vector2(8,0), Vector2(0,14)])
		mark.position = Vector2(x, 225)
		mark.color = Color("#e06b43")
		add_child(mark)
