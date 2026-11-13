extends CombatantBase
class_name SrbosBoss

## Srbos: jefe independiente del sector Orgullo.
## Sus tres ataques se basan en las habilidades descritas en el documento de diseño.

@export_group("Integración con sectores")
@export var boss_display_name: String = "Srbos"
@export var sector_type: String = "Orgullo"
@export var confined_to_room: bool = true
@export var room_half_extents: Vector2 = Vector2(238.0, 138.0)
var confined_center_global: Vector2 = Vector2.ZERO

@export_group("Movimiento")
@export var movement_speed: float = 52.0
@export var minimum_separation: float = 46.0
@export var preferred_distance: float = 92.0

@export_group("Ataques")
@export var attack_cooldown: float = 1.8
@export var attack_windup: float = 0.9
@export var recovery_time: float = 0.7
@export var vertical_damage: int = 20
@export var horizontal_damage: int = 17
@export var spin_damage: int = 22
@export var vertical_lane_width: float = 44.0
@export var horizontal_lane_height: float = 48.0
@export var spin_radius: float = 112.0

@export_group("Acumulaciones de Orgullo")
@export var max_pride_stacks: int = 10
@export var damage_per_stack: float = 0.02
@export var speed_per_stack: float = 0.01

var player: CharacterBody2D
var state: StringName = &"idle"
var state_timer: float = 0.0
var cooldown_timer: float = 1.2
var attack_index: int = -1
var target_position: Vector2 = Vector2.ZERO
var pride_stacks: int = 0
var indicator: Line2D
var death_animation_started: bool = false

func _ready() -> void:
    super._ready()
    if animated_sprite != null:
        animated_sprite.animation_finished.connect(_on_sprite_animation_finished)
        _play_idle()
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

    if state == &"preparing":
        state_timer -= delta
        velocity = Vector2.ZERO
        move_and_slide()
        if state_timer <= 0.0:
            _execute_attack()
            state = &"recovering"
            state_timer = recovery_time
            _clear_indicator()
        return

    if state == &"recovering":
        state_timer -= delta
        velocity = Vector2.ZERO
        move_and_slide()
        if state_timer <= 0.0:
            state = &"idle"
            _play_idle()
        return

    _approach_player()
    if cooldown_timer <= 0.0:
        _begin_attack()

func _find_player() -> void:
    if is_instance_valid(player):
        return
    var candidate := get_tree().get_first_node_in_group("player")
    if candidate is CharacterBody2D:
        player = candidate as CharacterBody2D

func _approach_player() -> void:
    var offset := player.global_position - global_position
    var distance := offset.length()
    if distance <= minimum_separation:
        velocity = Vector2.ZERO
        move_and_slide()
        return
    if distance > preferred_distance + 18.0:
        velocity = offset.normalized() * _current_speed()
    elif distance < preferred_distance - 22.0:
        velocity = -offset.normalized() * _current_speed() * 0.45
    else:
        velocity = Vector2.ZERO
    move_and_slide()
    _keep_inside_room()
    _update_facing()
    if velocity.length() > 1.0:
        _play_animation(&"caminar")

func _current_speed() -> float:
    return movement_speed * (1.0 + float(pride_stacks) * speed_per_stack)

func _keep_inside_room() -> void:
    if not confined_to_room:
        return
    global_position.x = clampf(global_position.x, confined_center_global.x - room_half_extents.x, confined_center_global.x + room_half_extents.x)
    global_position.y = clampf(global_position.y, confined_center_global.y - room_half_extents.y, confined_center_global.y + room_half_extents.y)

func _update_facing() -> void:
    if animated_sprite == null or not is_instance_valid(player):
        return
    var direction := player.global_position - global_position
    if absf(direction.x) > absf(direction.y):
        animated_sprite.flip_h = direction.x < 0.0

func _begin_attack() -> void:
    attack_index = (attack_index + 1) % 3
    cooldown_timer = attack_cooldown
    state = &"preparing"
    state_timer = attack_windup
    velocity = Vector2.ZERO
    target_position = player.global_position
    _play_animation(&"ataque")
    _show_attack_warning()

func _show_attack_warning() -> void:
    _clear_indicator()
    indicator = Line2D.new()
    indicator.width = 5.0
    indicator.default_color = Color(1.0, 0.25, 0.2, 0.72)
    indicator.z_index = 20
    var points := PackedVector2Array()
    var left := confined_center_global.x - room_half_extents.x
    var right := confined_center_global.x + room_half_extents.x
    var top := confined_center_global.y - room_half_extents.y
    var bottom := confined_center_global.y + room_half_extents.y

    match attack_index:
        0:
            var x := clampf(target_position.x, left + 12.0, right - 12.0)
            points.append(Vector2(x, top))
            points.append(Vector2(x, bottom))
        1:
            var y := clampf(target_position.y, top + 12.0, bottom - 12.0)
            points.append(Vector2(left, y))
            points.append(Vector2(right, y))
        2:
            for i in range(49):
                var angle := TAU * float(i) / 48.0
                points.append(global_position + Vector2(cos(angle), sin(angle)) * spin_radius)
    indicator.points = points
    get_tree().current_scene.add_child(indicator)

func _execute_attack() -> void:
    if not is_instance_valid(player):
        return

    match attack_index:
        0:
            _vertical_strike()
        1:
            _horizontal_strike()
        2:
            _spinning_strike()

func _vertical_strike() -> void:
    # Golpe vertical: una columna marcada atraviesa la sala.
    var left := confined_center_global.x - room_half_extents.x
    var right := confined_center_global.x + room_half_extents.x
    var top := confined_center_global.y - room_half_extents.y
    var bottom := confined_center_global.y + room_half_extents.y
    var strike_x := clampf(target_position.x, left + 12.0, right - 12.0)
    var p := player.global_position
    var inside_lane := absf(p.x - strike_x) <= vertical_lane_width * 0.5 and p.y >= top and p.y <= bottom

    if inside_lane:
        _damage_player(vertical_damage)
    else:
        _gain_pride_stack()

func _horizontal_strike() -> void:
    # Ataque horizontal: una franja cruza toda la sala a la altura marcada.
    var left := confined_center_global.x - room_half_extents.x
    var right := confined_center_global.x + room_half_extents.x
    var top := confined_center_global.y - room_half_extents.y
    var bottom := confined_center_global.y + room_half_extents.y
    var strike_y := clampf(target_position.y, top + 12.0, bottom - 12.0)
    var p := player.global_position
    if absf(p.y - strike_y) <= horizontal_lane_height * 0.5 and p.x >= left and p.x <= right:
        _damage_player(horizontal_damage)

func _spinning_strike() -> void:
    # Ataque giratorio: golpe circular alrededor de Srbos.
    if player.global_position.distance_to(global_position) <= spin_radius:
        _damage_player(spin_damage)

func _damage_player(base_damage: int) -> void:
    if not is_instance_valid(player) or not player.has_method("take_damage"):
        return
    var final_damage := maxi(1, roundi(float(base_damage) * (1.0 + float(pride_stacks) * damage_per_stack)))
    player.take_damage(final_damage, global_position)

func _gain_pride_stack() -> void:
    if pride_stacks >= max_pride_stacks:
        return
    pride_stacks += 1
    queue_redraw()
    print("Srbos aumenta su Orgullo: ", pride_stacks, "/", max_pride_stacks)

func _play_idle() -> void:
    if animated_sprite == null or animated_sprite.sprite_frames == null:
        return
    var anim: StringName = &"idle_frente"
    if is_instance_valid(player):
        var direction := player.global_position - global_position
        if absf(direction.x) > absf(direction.y):
            anim = &"idle_derecha" if direction.x >= 0.0 else &"idle_izquierda"
        elif direction.y < 0.0:
            anim = &"idle_espalda"
    _play_animation(anim)

func _play_animation(anim: StringName) -> void:
    if animated_sprite == null or animated_sprite.sprite_frames == null:
        return
    if animated_sprite.sprite_frames.has_animation(anim):
        if animated_sprite.animation != anim or not animated_sprite.is_playing():
            animated_sprite.play(anim)

func _on_sprite_animation_finished() -> void:
    if is_dead and animated_sprite.animation == &"muerte":
        queue_free()

func _clear_indicator() -> void:
    if is_instance_valid(indicator):
        indicator.queue_free()
    indicator = null

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
    if is_dead:
        return
    super.take_damage(amount, attacker_position)
    queue_redraw()
    if not is_dead:
        _play_animation(&"dano")

func _defeat() -> void:
    if is_dead:
        return
    is_dead = true
    remove_from_group("enemies")
    velocity = Vector2.ZERO
    set_physics_process(false)
    _disable_collisions()
    _clear_indicator()
    if sector_type != "":
        GameData.grant_soul_fragment("Orgullo")
    GameData.mark_sector_cleared(sector_type)
    if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(&"muerte"):
        animated_sprite.play(&"muerte")
    else:
        queue_free()
    queue_redraw()

func _disable_collisions() -> void:
    for child in get_children():
        if child is CollisionShape2D:
            (child as CollisionShape2D).set_deferred("disabled", true)

func _draw() -> void:
    if is_dead:
        return
    var width := 92.0
    var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(-58.0, -72.0), "MINIJEFE: " + boss_display_name, HORIZONTAL_ALIGNMENT_CENTER, 116.0, 11, Color("#ffe29a"))
    draw_rect(Rect2(-width / 2.0, -61.0, width, 7.0), Color("#421c27"))
    draw_rect(Rect2(-width / 2.0, -61.0, width * ratio, 7.0), Color("#e74c3c"))
    if pride_stacks > 0:
        draw_string(ThemeDB.fallback_font, Vector2(-35.0, -78.0), "ORGULLO " + str(pride_stacks) + "/10", HORIZONTAL_ALIGNMENT_CENTER, 70.0, 9, Color("#d9b7ff"))
