extends CombatantBase
class_name AnclisBoss

## Anclis: IA y patrones de ataque independientes.

@export_group("Integración con sectores")
@export var boss_display_name: String = "Anclis"
@export var sector_type: String = "Hermandad"
@export var confined_to_room: bool = true
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)
var confined_center_global: Vector2 = Vector2.ZERO

@export_group("Movimiento")
@export var movement_speed: float = 42.0
@export var preferred_distance: float = 150.0
@export var detection_range: float = 360.0

@export_group("Combate")
@export var attack_cooldown: float = 1.6
@export var attack_windup: float = 0.65
@export var recovery_time: float = 0.55

const PROJECTILE_SCRIPT: Script = preload("res://scripts/bosses/anclis_projectile.gd")

var player: CharacterBody2D
var state: StringName = &"idle"
var state_timer: float = 0.0
var cooldown_timer: float = 1.0
var next_attack_index: int = -1
var facing_direction: Vector2 = Vector2.LEFT

func _ready() -> void:
    super._ready()
    queue_redraw()

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    cooldown_timer = maxf(0.0, cooldown_timer - delta)
    _find_player()

    if not is_instance_valid(player):
        velocity = Vector2.ZERO
        move_and_slide()
        return

    var distance := global_position.distance_to(player.global_position)
    if distance > detection_range:
        velocity = Vector2.ZERO
        move_and_slide()
        state = &"idle"
        return

    if state == &"preparing":
        state_timer -= delta
        velocity = Vector2.ZERO
        move_and_slide()
        if state_timer <= 0.0:
            _execute_current_attack()
            state = &"recovering"
            state_timer = recovery_time
        return

    if state == &"recovering":
        state_timer -= delta
        velocity = Vector2.ZERO
        move_and_slide()
        if state_timer <= 0.0:
            state = &"idle"
        return

    _move_to_combat_distance()
    if cooldown_timer <= 0.0:
        _begin_next_attack()

func _find_player() -> void:
    if is_instance_valid(player):
        return
    var candidate := get_tree().get_first_node_in_group("player")
    if candidate is CharacterBody2D:
        player = candidate as CharacterBody2D

func _move_to_combat_distance() -> void:
    var offset := player.global_position - global_position
    var distance := offset.length()
    if distance > 0.001:
        facing_direction = offset.normalized()

    if distance > preferred_distance + 24.0:
        velocity = facing_direction * movement_speed
    elif distance < preferred_distance - 30.0:
        velocity = -facing_direction * movement_speed * 0.65
    else:
        velocity = Vector2.ZERO

    move_and_slide()
    _keep_inside_room()

func _keep_inside_room() -> void:
    if not confined_to_room:
        return
    global_position.x = clampf(global_position.x, confined_center_global.x - room_half_extents.x, confined_center_global.x + room_half_extents.x)
    global_position.y = clampf(global_position.y, confined_center_global.y - room_half_extents.y, confined_center_global.y + room_half_extents.y)

func _begin_next_attack() -> void:
    state = &"preparing"
    state_timer = attack_windup
    cooldown_timer = attack_cooldown
    velocity = Vector2.ZERO
    next_attack_index = (next_attack_index + 1) % 3

func _execute_current_attack() -> void:
    match next_attack_index:
        0:
            _attack_memory_return()
        1:
            _attack_farewell_drop()
        2:
            _attack_no_return()

func _attack_memory_return() -> void:
    # Efera de recuerdo: persigue a Isaac, rebota dos veces y vuelve a Anclis.
    var direction := global_position.direction_to(player.global_position)
    _spawn_projectile(global_position + direction * 28.0, direction * 185.0, 15,
        AnclisProjectile.Mode.BOUNCE_RETURN, 2, 0.0, 0.0)

func _attack_farewell_drop() -> void:
    # Efera de despedida: cae donde estaba Isaac al comenzar el ataque.
    var target := player.global_position
    var spawn_position := target + Vector2(0.0, -170.0)
    spawn_position.x = clampf(spawn_position.x,
        confined_center_global.x - room_half_extents.x + 12.0,
        confined_center_global.x + room_half_extents.x - 12.0)
    _spawn_projectile(spawn_position, Vector2.ZERO, 18,
        AnclisProjectile.Mode.FALL, 0, target.y, 430.0)

func _attack_no_return() -> void:
    # Efera sin retorno: carga y dispara una esfera rápida hacia Isaac.
    var direction := global_position.direction_to(player.global_position)
    _spawn_projectile(global_position + direction * 30.0, direction * 300.0, 20,
        AnclisProjectile.Mode.STRAIGHT, 0, 0.0, 0.0)

func _spawn_projectile(spawn_position: Vector2, initial_velocity: Vector2,
        damage: int, projectile_mode: int, bounces: int, target_y: float, gravity: float) -> void:
    var projectile := Area2D.new()
    projectile.name = "AnclisOrb"
    projectile.set_script(PROJECTILE_SCRIPT)
    projectile.set("damage", damage)
    projectile.set("mode", projectile_mode)
    projectile.set("velocity", initial_velocity)
    projectile.set("remaining_bounces", bounces)
    projectile.set("target_y", target_y)
    projectile.set("fall_gravity", gravity)
    projectile.set("room_center", confined_center_global)
    projectile.set("room_half_extents", room_half_extents)
    projectile.set("return_target", self)

    var collision := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 9.0
    collision.shape = circle
    projectile.add_child(collision)

    var visual := Polygon2D.new()
    visual.name = "OrbVisual"
    visual.polygon = PackedVector2Array([
        Vector2(0, -9), Vector2(7, -5), Vector2(9, 2),
        Vector2(3, 9), Vector2(-5, 7), Vector2(-9, 0), Vector2(-5, -7)
    ])
    visual.color = Color("#8ec4c9")
    projectile.add_child(visual)

    projectile.global_position = spawn_position
    projectile.collision_layer = 0
    projectile.collision_mask = 3
    get_tree().current_scene.add_child(projectile)

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
    if is_dead:
        return
    super.take_damage(amount, attacker_position)
    queue_redraw()

func _defeat() -> void:
    if is_dead:
        return
    if sector_type != "":
        GameData.grant_soul_fragment("Hermandad")
    GameData.mark_sector_cleared(sector_type)
    super._defeat()

func _draw() -> void:
    if is_dead:
        return
    var width := 74.0
    var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(-55.0, -57.0),
        "MINIJEFE: " + boss_display_name, HORIZONTAL_ALIGNMENT_CENTER, 110.0, 10, Color("#ffe29a"))
    draw_rect(Rect2(-width / 2.0, -48.0, width, 6.0), Color("#421c27"))
    draw_rect(Rect2(-width / 2.0, -48.0, width * ratio, 6.0), Color("#e74c3c"))
