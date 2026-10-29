extends Node2D
# Llama de antorcha animada: parpadea, se mece y proyecta un halo cálido.
# La crea room_editor.gd al ejecutar el juego (en el editor 2D se ve la versión estática).

@export var flame_color: Color = Color("#e06b43")
@export var core_color: Color = Color("#ffe5a0")
@export var glow_radius: float = 34.0

var _t: float = 0.0
var _flicker: float = 1.0
var _sway: float = 0.0

func _ready() -> void:
	# Fase aleatoria para que las antorchas no parpadeen todas a la vez
	_t = randf() * 100.0
	# Solo se anima cuando la antorcha está en pantalla (hay muchas salas en el mapa)
	var margin := glow_radius + 8.0
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-margin, -margin, margin * 2.0, margin * 2.0)
	add_child(notifier)
	notifier.screen_entered.connect(set_process.bind(true))
	notifier.screen_exited.connect(set_process.bind(false))
	set_process(false)

func _process(delta: float) -> void:
	_t += delta
	# Mezcla de tres ondas = parpadeo irregular, sin saltos bruscos
	var n := sin(_t * 7.3) * 0.5 + sin(_t * 11.7 + 1.3) * 0.3 + sin(_t * 19.1 + 4.1) * 0.2
	_flicker = 1.0 + 0.18 * n
	_sway = sin(_t * 5.1) * 1.6
	queue_redraw()

func _draw() -> void:
	# Halo (dos capas translúcidas)
	var c := flame_color
	draw_circle(Vector2.ZERO, glow_radius * (0.85 + 0.15 * _flicker), Color(c.r, c.g, c.b, 0.07))
	draw_circle(Vector2.ZERO, glow_radius * 0.55 * _flicker, Color(c.r, c.g, c.b, 0.10))

	# Llama en forma de gota
	var h := 13.0 * _flicker
	var w := 6.5
	var outer := PackedVector2Array([
		Vector2(-w, 3.0),
		Vector2(-w * 0.8, -h * 0.3),
		Vector2(_sway, -h),
		Vector2(w * 0.8, -h * 0.3),
		Vector2(w, 3.0),
		Vector2(0.0, 6.0),
	])
	draw_colored_polygon(outer, flame_color)

	# Núcleo claro
	var ih := h * 0.55
	var iw := w * 0.5
	var inner := PackedVector2Array([
		Vector2(-iw, 3.0),
		Vector2(-iw * 0.8, -ih * 0.3),
		Vector2(_sway * 0.6, -ih),
		Vector2(iw * 0.8, -ih * 0.3),
		Vector2(iw, 3.0),
		Vector2(0.0, 5.0),
	])
	draw_colored_polygon(inner, core_color)
