extends CombatantBase
class_name AmyBoss

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var boss_display_name := "Amy"
@export var sector_type := "Amor"
@export var confined_to_room := true
@export var room_half_extents := Vector2(238.0, 138.0)
var confined_center_global := Vector2.ZERO
@export var spare_distance := 72.0
var player: CharacterBody2D
var spared := false
var prompt_label: Label

func _ready() -> void:
	super._ready()
	prompt_label = Label.new()
	prompt_label.text = "E: Hablar / perdonar"
	prompt_label.position = Vector2(-75, -70)
	add_child(prompt_label)

func _play_anim(anim: StringName) -> void:
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)

func _update_visual_motion() -> void:
	if sprite == null or is_dead:
		return
	if velocity.length() > 1.0:
		_play_anim(&"caminar")
	else:
		_play_anim(&"idle_frente")

func _physics_process(_delta: float) -> void:
	if is_dead or spared: return
	if not is_instance_valid(player):
		var found := get_tree().get_first_node_in_group("player")
		if found is CharacterBody2D: player = found
	if is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead or spared or not is_instance_valid(player): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if global_position.distance_to(player.global_position) <= spare_distance:
			_spare_amy()

func _spare_amy() -> void:
	_play_anim(&"perdonar")
	spared = true
	GameData.amy_spared = true
	GameData.grant_soul_fragment("Amor")
	if not GameData.spared_bosses.has("Amy"):
		GameData.spared_bosses.append("Amy")
	GameData.mark_sector_cleared(sector_type)
	remove_from_group("enemies")
	set_physics_process(false)
	set_process_input(false)
	if prompt_label: prompt_label.text = "Gracias por escucharme"
	if has_node("Sprite2D"):
		(get_node("Sprite2D") as Sprite2D).modulate = Color(1.0, 0.85, 0.9)

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	_play_anim(&"dano")
	if is_dead or spared: return
	super.take_damage(amount, attacker_position)
	queue_redraw()

func _defeat() -> void:
	_play_anim(&"muerte")
	if is_dead: return
	_update_visual_motion()
	GameData.grant_soul_fragment("Amor")
	super._defeat()
	GameData.mark_sector_cleared(sector_type)
	_drop_healing_potion()

func _drop_healing_potion() -> void:
	var orb := Area2D.new()
	orb.name = "AmyHealingPotion"
	orb.position = Vector2.ZERO
	orb.collision_layer = 0
	orb.collision_mask = 2
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	shape_node.shape = shape
	orb.add_child(shape_node)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(0,-12),Vector2(9,-5),Vector2(7,10),Vector2(-7,10),Vector2(-9,-5)])
	visual.color = Color("#ef79a5")
	orb.add_child(visual)
	orb.body_entered.connect(_on_potion_body_entered.bind(orb))
	get_tree().current_scene.add_child(orb)
	orb.global_position = global_position

func _on_potion_body_entered(body: Node2D, orb: Area2D) -> void:
	if body.is_in_group("player"):
		if body.get("health") != null and body.get("max_health") != null:
			body.set("health", mini(int(body.get("max_health")), int(body.get("health"))+20))
			if body.has_signal("health_changed"):
				body.emit_signal("health_changed", body.get("health"), body.get("max_health"))
		orb.queue_free()

func _draw() -> void:
	if is_dead or spared: return
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-42, -48), "AMY", HORIZONTAL_ALIGNMENT_CENTER, 84, 11, Color("#ffc4d9"))
	draw_rect(Rect2(-36, -40, 72, 6), Color("#492b3b"))
	draw_rect(Rect2(-36, -40, 72 * ratio, 6), Color("#e98caf"))
