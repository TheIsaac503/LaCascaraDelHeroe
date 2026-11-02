
extends "res://scripts/enemy.gd"

# --------------------------------------------------
# CONFIGURACIÓN PROPIA DE EL ORGULLO
# --------------------------------------------------

@export_group("Ataque de El Orgullo")
@export var orgullo_damage: int = 20
@export var orgullo_attack_range: float = 75.0
@export var orgullo_cooldown: float = 1.5

var orgullo_attack_timer: float = 0.0


# --------------------------------------------------
# ATAQUE PRINCIPAL
# --------------------------------------------------

func _attack_player() -> void:
	if is_dead or is_attacking:
		return

	if not is_instance_valid(player):
		return

	if orgullo_attack_timer > 0.0:
		return

	# Comenzar ataque
	is_attacking = true
	contact_cooldown = orgullo_cooldown
	orgullo_attack_timer = orgullo_cooldown

	velocity = Vector2.ZERO

	# Orientar el personaje hacia Isaac
	var direction := global_position.direction_to(player.global_position)

	if sprite != null:
		sprite.flip_h = direction.x < 0.0

		# Reproducir animación
		if sprite.sprite_frames != null:
			if sprite.sprite_frames.has_animation("ataque"):
				sprite.play("ataque")
			elif sprite.sprite_frames.has_animation("attack"):
				sprite.play("attack")

	# Comprobar distancia antes de causar daño
	var distance := global_position.distance_to(player.global_position)

	if distance <= orgullo_attack_range:
		if player.has_method("take_damage"):
			print("¡El Orgullo golpeó a Isaac!")
			player.take_damage(orgullo_damage)


# --------------------------------------------------
# CONTROL DE ANIMACIONES
# --------------------------------------------------

func _on_animation_finished() -> void:
	if sprite == null:
		return

	if sprite.animation == "ataque" or sprite.animation == "attack":
		is_attacking = false


# --------------------------------------------------
# TEMPORIZADOR DE HABILIDADES
# --------------------------------------------------

func _physics_process(delta: float) -> void:
	orgullo_attack_timer = maxf(0.0, orgullo_attack_timer - delta)

	super._physics_process(delta)

func _update_animation() -> void:
	if sprite == null or sprite.sprite_frames == null or is_dead:
		return

	if is_attacking:
		return

	var anim := "caminar"

	if velocity.length() < 1.0:
		anim = "idle_frente"

	if absf(velocity.x) > absf(velocity.y):
		anim = "idle_derecha" if velocity.x > 0.0 else "idle_izquierda"
	elif velocity.y < 0.0:
		anim = "idle_espalda"
	elif velocity.y > 0.0:
		anim = "idle_frente"

	if velocity.length() > 1.0:
		anim = "caminar"

	if sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
