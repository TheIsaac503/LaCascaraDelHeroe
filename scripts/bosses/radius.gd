extends CombatantBase
class_name RadiusBoss

@export_group("Integración con sectores")
@export var boss_display_name: String = "Radius"
@export var sector_type: String = "Ira"
@export var confined_to_room: bool = true
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)
var confined_center_global: Vector2 = Vector2.ZERO

@export_group("Ataques")
@export var movement_speed: float = 58.0
@export var charge_damage: int = 24
@export var rock_damage: int = 15
@export var repel_threshold: float = 0.25
@export var repel_force: float = 250.0
@export var attack_cooldown: float = 2.0
@export var windup: float = 0.7

var player: CharacterBody2D
var state: StringName = &"idle"
var timer: float = 0.0
var cooldown: float = 1.0
var attack_index: int = -1
var target_position: Vector2 = Vector2.ZERO
var next_repel_health: int = 0

func _ready() -> void:
    super._ready()
    next_repel_health = maxi(1, int(ceil(float(max_health) * (1.0 - repel_threshold))))
    queue_redraw()

func _physics_process(delta: float) -> void:
    if is_dead: return
    cooldown = maxf(0.0, cooldown - delta)
    _find_player()
    if not is_instance_valid(player):
        velocity = Vector2.ZERO
        move_and_slide()
        return
    if state == &"preparing":
        timer -= delta
        velocity = Vector2.ZERO
        move_and_slide()
        if timer <= 0.0:
            _execute_attack()
            state = &"recovering"
            timer = 0.75
        return
    if state == &"recovering":
        timer -= delta
        velocity = Vector2.ZERO
        move_and_slide()
        if timer <= 0.0: state = &"idle"
        return
    var offset := player.global_position - global_position
    velocity = offset.normalized() * movement_speed if offset.length() > 65.0 else Vector2.ZERO
    move_and_slide()
    _keep_inside_room()
    if cooldown <= 0.0:
        attack_index = (attack_index + 1) % 2
        target_position = player.global_position
        state = &"preparing"
        timer = windup
        cooldown = attack_cooldown

func _find_player() -> void:
    if is_instance_valid(player): return
    var candidate := get_tree().get_first_node_in_group("player")
    if candidate is CharacterBody2D: player = candidate as CharacterBody2D

func _keep_inside_room() -> void:
    if confined_to_room:
        global_position.x = clampf(global_position.x, confined_center_global.x - room_half_extents.x, confined_center_global.x + room_half_extents.x)
        global_position.y = clampf(global_position.y, confined_center_global.y - room_half_extents.y, confined_center_global.y + room_half_extents.y)

func _execute_attack() -> void:
    if attack_index == 0:
        _charge()
    else:
        _throw_rocks()

func _charge() -> void:
    if not is_instance_valid(player): return
    var direction := global_position.direction_to(player.global_position)
    var start := global_position
    global_position += direction * 125.0
    _keep_inside_room()
    if player.global_position.distance_to(start) < 155.0 and player.global_position.distance_to(global_position) < 85.0:
        _damage_player(charge_damage)

func _throw_rocks() -> void:
    if not is_instance_valid(player): return
    var base := global_position.direction_to(target_position)
    for angle in [-0.22, 0.0, 0.22]:
        var rock := BossProjectile.new()
        rock.damage = rock_damage
        rock.velocity = base.rotated(angle) * 235.0 + Vector2(0, -80.0)
        rock.fall_gravity = 260.0
        rock.radius = 9.0
        get_tree().current_scene.add_child(rock)
        rock.global_position = global_position + base * 25.0
        (rock.get_child(1) as Polygon2D).color = Color("#b98b72")

func _damage_player(amount: int) -> void:
    if is_instance_valid(player) and player.has_method("take_damage"):
        player.take_damage(amount, global_position)

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
    if is_dead: return
    var old_health := health
    super.take_damage(amount, attacker_position)
    if is_dead: return
    if health <= next_repel_health and old_health > next_repel_health:
        _repel_player()
        next_repel_health = maxi(0, next_repel_health - int(ceil(float(max_health) * repel_threshold)))
    queue_redraw()

func _repel_player() -> void:
    if not is_instance_valid(player): _find_player()
    if is_instance_valid(player):
        var direction := (player.global_position - global_position).normalized()
        player.velocity = direction * repel_force
        if player.has_method("move_and_slide"):
            player.move_and_slide()

func _defeat() -> void:
    if is_dead: return
    GameData.grant_soul_fragment("Ira")
    GameData.mark_sector_cleared(sector_type)
    super._defeat()

func _draw() -> void:
    if is_dead: return
    var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(-55, -55), "MINIJEFE: " + boss_display_name, HORIZONTAL_ALIGNMENT_CENTER, 110, 10, Color("#ffe29a"))
    draw_rect(Rect2(-37, -46, 74, 6), Color("#421c27"))
    draw_rect(Rect2(-37, -46, 74 * ratio, 6), Color("#e06b43"))
