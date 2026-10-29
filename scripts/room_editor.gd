@tool
extends Node2D

@export_range(1, 6, 1) var room_number: int = 1
@export var room_title: String = "ENTRADA"
@export var sector_color: Color = Color("#4b2928")
@export var accent_color: Color = Color("#e06b43")
@export var show_left_door: bool = true
@export var show_right_door: bool = true
@export var show_top_door: bool = false
@export var show_bottom_door: bool = false

const W := 560.0
const H := 360.0
const WALL := 24.0
const GAP := 104.0
const FLOOR_TEXTURE: Texture2D = preload("res://assets/tiles/tiles_suelo/suelo_01.png")

func _draw() -> void:
	var rect := Rect2(-W / 2.0, -H / 2.0, W, H)
	draw_rect(rect, sector_color)
	# Baldosas pixel art: textura repetida con una capa de tinte propia del sector.
	var tile_size := 32.0
	var start_x := -W / 2.0
	var start_y := -H / 2.0
	var row := 0
	while start_y < H / 2.0:
		var col := 0
		start_x = -W / 2.0
		while start_x < W / 2.0:
			var tile_rect := Rect2(start_x, start_y, tile_size, tile_size)
			draw_texture_rect(FLOOR_TEXTURE, tile_rect, false, Color(1, 1, 1, 0.72))
			# Sutiles variaciones de piedra para que no parezca un patrón plano.
			if (col + row) % 4 == 0:
				draw_rect(Rect2(start_x + 5, start_y + 6, 3, 2), accent_color.darkened(0.45), false, 1.0)
			start_x += tile_size
			col += 1
		start_y += tile_size
		row += 1
	var stone := Color("#292631")
# Puertas laterales
	_draw_side(-W / 2.0, show_left_door, stone)
	_draw_side(W / 2.0, show_right_door, stone)

# Puertas superior e inferior
	_draw_horizontal_door(-H / 2.0, bool(show_top_door), stone)
	_draw_horizontal_door(H / 2.0, bool(show_bottom_door), stone)
	# Juntas de los bloques del muro: relieve discreto, sin cubrir las puertas.
	for wall_y in [-H / 2.0 + 5.0, H / 2.0 - 5.0]:
		for block_x in range(0, 8):
			var bx := -W / 2.0 + float(block_x) * 72.0 + (12.0 if wall_y < 0.0 else 0.0)
			draw_line(Vector2(bx, wall_y - 4.0), Vector2(bx, wall_y + 4.0), Color(0.08, 0.07, 0.10, 0.55), 2.0)
	
	# Antorchas en las esquinas.
	for torch_pos in [Vector2(-W / 2.0 + 38, -H / 2.0 + 38), Vector2(W / 2.0 - 38, -H / 2.0 + 38), Vector2(-W / 2.0 + 38, H / 2.0 - 38), Vector2(W / 2.0 - 38, H / 2.0 - 38)]:
		draw_circle(torch_pos, 15, Color(accent_color.r, accent_color.g, accent_color.b, 0.12))
		draw_rect(Rect2(torch_pos + Vector2(-3, 5), Vector2(6, 12)), Color("#60412f"))
		draw_circle(torch_pos, 8, accent_color)
		draw_circle(torch_pos + Vector2(-1, -2), 4, Color("#ffe5a0"))
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(-110, -H / 2.0 + 52), "SALA " + str(room_number), HORIZONTAL_ALIGNMENT_CENTER, 220, 17, accent_color)
		draw_string(font, Vector2(-130, -H / 2.0 + 75), room_title, HORIZONTAL_ALIGNMENT_CENTER, 260, 13, Color("#f0e7d5"))
		
	# Detalles por tipo de sala visibles en el editor.
	if room_number == 3:
		draw_rect(Rect2(-30, 15, 60, 36), Color("#3b302e"), false, 3.0)
		if font: draw_string(font, Vector2(-85, 75), "ZONA DE RESCATE", HORIZONTAL_ALIGNMENT_CENTER, 170, 12, accent_color)
	elif room_number == 5:
		draw_rect(Rect2(-35, -8, 70, 42), accent_color.darkened(0.55), false, 3.0)
		if font: draw_string(font, Vector2(-90, 70), "RECOMPENSA", HORIZONTAL_ALIGNMENT_CENTER, 180, 12, accent_color)
	elif room_number == 6:
		draw_circle(Vector2.ZERO, 48, accent_color.darkened(0.55), false, 4.0)
		draw_circle(Vector2.ZERO, 30, accent_color, false, 2.0)
		if font: draw_string(font, Vector2(-100, 85), "CÁMARA DEL JEFE", HORIZONTAL_ALIGNMENT_CENTER, 200, 13, accent_color)

func _draw_side(x: float, door_open: bool, color: Color) -> void:
	if door_open:
		var segment := (H - GAP) / 2.0
		draw_rect(Rect2(x - WALL / 2.0, -H / 2.0, WALL, segment), color)
		draw_rect(Rect2(x - WALL / 2.0, GAP / 2.0, WALL, segment), color)
		# Marca visual de la puerta.
		draw_line(Vector2(x, -GAP / 2.0), Vector2(x, GAP / 2.0), accent_color, 3.0)
	else:
		draw_rect(Rect2(x - WALL / 2.0, -H / 2.0, WALL, H), color)

func _draw_horizontal_door(y: float, door_open: bool, color: Color) -> void:
	var segment := (W - GAP) / 2.0

	if door_open:
		draw_rect(Rect2(-W / 2.0, y, segment, WALL), color)
		draw_rect(Rect2(GAP / 2.0, y, segment, WALL), color)

		draw_line(
			Vector2(-GAP / 2.0, y + WALL / 2.0),
			Vector2(GAP / 2.0, y + WALL / 2.0),
			accent_color,
			3.0
		)
	else:
		draw_rect(Rect2(-W / 2.0, y, W, WALL), color)
