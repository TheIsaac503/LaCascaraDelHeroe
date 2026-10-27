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

func _draw() -> void:
	var rect := Rect2(-W / 2.0, -H / 2.0, W, H)
	draw_rect(rect, sector_color)
	# Suelo estilo mazmorra cenital: losas y bordes de piedra.
	for i in range(1, 7):
		var x := -W / 2.0 + float(i) * W / 7.0
		draw_line(Vector2(x, -H / 2.0 + WALL), Vector2(x, H / 2.0 - WALL), Color(0.05, 0.05, 0.07, 0.23), 2.0)
	for i in range(1, 4):
		var y := -H / 2.0 + float(i) * H / 4.0
		draw_line(Vector2(-W / 2.0 + WALL, y), Vector2(W / 2.0 - WALL, y), Color(0.05, 0.05, 0.07, 0.23), 2.0)
	var stone := Color("#20232d")
# Puertas laterales
	_draw_side(-W / 2.0, show_left_door, stone)
	_draw_side(W / 2.0, show_right_door, stone)

# Puertas superior e inferior
	_draw_horizontal_door(-H / 2.0, bool(show_top_door), stone)
	_draw_horizontal_door(H / 2.0 - WALL, bool(show_bottom_door), stone)
	
	# Antorchas en las esquinas.
	draw_circle(Vector2(-W / 2.0 + 38, -H / 2.0 + 38), 9, accent_color)
	draw_circle(Vector2(W / 2.0 - 38, -H / 2.0 + 38), 9, accent_color)
	draw_circle(Vector2(-W / 2.0 + 38, H / 2.0 - 38), 7, accent_color.darkened(0.2))
	draw_circle(Vector2(W / 2.0 - 38, H / 2.0 - 38), 7, accent_color.darkened(0.2))
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
