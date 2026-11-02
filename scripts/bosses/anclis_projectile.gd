extends Area2D
class_name AnclisProjectile

enum Mode { BOUNCE_RETURN, FALL, STRAIGHT }

@export var damage: int = 12
@export var mode: Mode = Mode.STRAIGHT
@export var velocity: Vector2 = Vector2.ZERO
@export var remaining_bounces: int = 0
@export var target_y: float = 0.0
@export var fall_gravity: float = 0.0
@export var room_center: Vector2 = Vector2.ZERO
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)

var return_target: Node2D
var lifetime: float = 0.0
var hit_player: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > 7.0:
		queue_free()
		return

	match mode:
		Mode.BOUNCE_RETURN:
			_move_bouncing(delta)
		Mode.FALL:
			velocity.y += fall_gravity * delta
			global_position += velocity * delta
			if global_position.y >= target_y:
				queue_free()
		Mode.STRAIGHT:
			global_position += velocity * delta

func _move_bouncing(delta: float) -> void:
	if remaining_bounces <= 0 and is_instance_valid(return_target):
		velocity = global_position.direction_to(return_target.global_position) * 210.0
		global_position += velocity * delta
		if global_position.distance_to(return_target.global_position) < 20.0:
			queue_free()
		return

	global_position += velocity * delta
	var min_x := room_center.x - room_half_extents.x + 10.0
	var max_x := room_center.x + room_half_extents.x - 10.0
	var min_y := room_center.y - room_half_extents.y + 10.0
	var max_y := room_center.y + room_half_extents.y - 10.0
	var bounced := false

	if global_position.x <= min_x or global_position.x >= max_x:
		velocity.x *= -1.0
		global_position.x = clampf(global_position.x, min_x, max_x)
		bounced = true
	if global_position.y <= min_y or global_position.y >= max_y:
		velocity.y *= -1.0
		global_position.y = clampf(global_position.y, min_y, max_y)
		bounced = true

	if bounced:
		remaining_bounces -= 1

func _on_body_entered(body: Node2D) -> void:
	if hit_player or not body.is_in_group("player"):
		return
	hit_player = true
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	queue_free()
