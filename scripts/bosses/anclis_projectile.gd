extends Area2D
class_name AnclisProjectile


enum Mode {
	BOUNCE_RETURN,
	FALL,
	STRAIGHT
}


var damage: int = 10

var mode: Mode = Mode.STRAIGHT

var velocity: Vector2 = Vector2.ZERO

var remaining_bounces: int = 0

var target_position: Vector2 = Vector2.ZERO

var room_center: Vector2 = Vector2.ZERO

var room_half_extents: Vector2 = Vector2(238.0, 138.0)

var return_target: Node2D

var fall_speed: float = 0.0

var lifetime: float = 8.0

var returning: bool = false

var hit_cooldown: float = 0.0


func _ready() -> void:

	body_entered.connect(
		_on_body_entered
	)


# ==================================================
# MOVIMIENTO
# ==================================================

func _physics_process(delta: float) -> void:

	lifetime -= delta


	if lifetime <= 0.0:

		queue_free()

		return


	hit_cooldown = maxf(
		0.0,
		hit_cooldown - delta
	)


	match mode:

		Mode.STRAIGHT:
			_move_straight(delta)

		Mode.BOUNCE_RETURN:
			_move_bounce_return(delta)

		Mode.FALL:
			_move_fall(delta)


# ==================================================
# ESFERA RECTA
# ==================================================

func _move_straight(delta: float) -> void:

	global_position += velocity * delta


	if not _inside_room():
		queue_free()


# ==================================================
# ESFERA QUE REBOTA Y REGRESA
# ==================================================

func _move_bounce_return(delta: float) -> void:

	if returning:

		if is_instance_valid(return_target):

			var direction := global_position.direction_to(
				return_target.global_position
			)


			global_position += direction * 230.0 * delta


			if global_position.distance_to(
				return_target.global_position
			) < 22.0:

				queue_free()

		else:

			queue_free()


		return


	global_position += velocity * delta


	var min_x := room_center.x - room_half_extents.x

	var max_x := room_center.x + room_half_extents.x

	var min_y := room_center.y - room_half_extents.y

	var max_y := room_center.y + room_half_extents.y


	var bounced := false


	if global_position.x < min_x or global_position.x > max_x:

		velocity.x *= -1.0

		global_position.x = clampf(
			global_position.x,
			min_x,
			max_x
		)

		bounced = true


	if global_position.y < min_y or global_position.y > max_y:

		velocity.y *= -1.0

		global_position.y = clampf(
			global_position.y,
			min_y,
			max_y
		)

		bounced = true


	if bounced:

		remaining_bounces -= 1


		if remaining_bounces <= 0:

			returning = true


# ==================================================
# ESFERA QUE CAE
# ==================================================

func _move_fall(delta: float) -> void:

	fall_speed += 650.0 * delta


	global_position.y += fall_speed * delta


	if global_position.y >= target_position.y:

		global_position = target_position

		_damage_player_at_landing()

		queue_free()


# ==================================================
# DAÑO POR CAÍDA
# ==================================================

func _damage_player_at_landing() -> void:

	var player := get_tree().get_first_node_in_group(
		"player"
	)


	if player == null:
		return


	if not player is CharacterBody2D:
		return


	var distance := global_position.distance_to(
		player.global_position
	)


	if distance <= 30.0:

		if player.has_method("take_damage"):

			player.take_damage(
				damage,
				global_position
			)


# ==================================================
# COLISIÓN CON JUGADOR
# ==================================================

func _on_body_entered(body: Node2D) -> void:

	if hit_cooldown > 0.0:
		return


	if body.is_in_group("player"):

		if body.has_method("take_damage"):

			body.take_damage(
				damage,
				global_position
			)


		hit_cooldown = 0.5


		if mode == Mode.STRAIGHT:

			queue_free()


# ==================================================
# COMPROBAR LÍMITES
# ==================================================

func _inside_room() -> bool:

	var min_x := room_center.x - room_half_extents.x

	var max_x := room_center.x + room_half_extents.x

	var min_y := room_center.y - room_half_extents.y

	var max_y := room_center.y + room_half_extents.y


	return (
		global_position.x >= min_x
		and global_position.x <= max_x
		and global_position.y >= min_y
		and global_position.y <= max_y
	)
