extends CharacterBody2D
class_name CombatantBase

signal health_changed(current_health: int, maximum_health: int)
signal defeated

@export_group("Salud")
@export var max_health: int = 40
@export var hurt_knockback: float = 90.0

var health: int = 0
var is_dead: bool = false

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _ready() -> void:
	max_health = maxi(1, max_health)
	health = max_health
	add_to_group("enemies")
	health_changed.emit(health, max_health)

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return

	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)

	if attacker_position != Vector2.ZERO:
		var push_direction := (global_position - attacker_position).normalized()
		if push_direction != Vector2.ZERO:
			velocity = push_direction * hurt_knockback

	_play_animation_if_available("hurt")
	_spawn_hit_sparks(global_position)

	if health <= 0:
		_defeat()

func _defeat() -> void:
	if is_dead:
		return

	is_dead = true
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	_disable_collisions()
	defeated.emit()

	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")
		if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.connect(_on_death_animation_finished)
	else:
		queue_free()

func _on_death_animation_finished() -> void:
	if animated_sprite != null and animated_sprite.animation == "die":
		queue_free()

func _disable_collisions() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)

func _play_animation_if_available(animation_name: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)


func _spawn_hit_sparks(hit_position: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 12
	particles.lifetime = 0.28
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color("#ffe28a")
	particles.global_position = hit_position
	get_tree().current_scene.add_child(particles)
	get_tree().create_timer(0.35).timeout.connect(particles.queue_free)
