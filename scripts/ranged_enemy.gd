extends CharacterBody2D

# Cargamos el proyectil que creamos en el Paso 1
@export var projectile_scene: PackedScene = preload("res://scenes/entities/Projectile.tscn")

var health := 40
var speed := 70.0
var attack_cooldown := 1.8
var can_attack := true

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
		
	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()
	
	# Mantener distancia: se acerca si está lejos, retrocede si Isaac está muy cerca
	if dist > 200:
		velocity = dir * speed
	elif dist < 100:
		velocity = -dir * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	if can_attack and dist < 300:
		_shoot_at_player(dir)

func _shoot_at_player(dir: Vector2) -> void:
	can_attack = false
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position
		proj.direction = dir
		get_parent().add_child(proj)
		
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	
	# Usamos attacker_position para calcular la dirección del empuje
	if attacker_position != Vector2.ZERO:
		var knockback_dir := (global_position - attacker_position).normalized()
		global_position += knockback_dir * 18.0
	
	_spawn_hit_sparks(global_position)
	
	modulate = Color(2.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	
	if health <= 0:
		queue_free()

func _spawn_hit_sparks(hit_position: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 12
	particles.lifetime = 0.25
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color("#e8c879") # Color dorado/chispa
	
	if hit_position != Vector2.ZERO:
		particles.global_position = hit_position
	else:
		particles.global_position = global_position
		
	get_parent().add_child(particles)
	
	# Eliminar el nodo de partículas automáticamente cuando termine
	await get_tree().create_timer(0.3).timeout
	particles.queue_free()
