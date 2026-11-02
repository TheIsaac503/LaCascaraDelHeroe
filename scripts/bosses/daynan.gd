extends CombatantBase
class_name DaynanBoss

@export var boss_display_name := "Daynan"
@export var sector_type := "Honor"
@export var confined_to_room := true
@export var room_half_extents := Vector2(238.0, 138.0)
var confined_center_global := Vector2.ZERO
@export var movement_speed := 76.0
@export var attack_cooldown := 1.7
@export var side_damage := 18
@export var horizontal_damage := 20
@export var spin_damage := 22
@export var deshonor_duration := 8.0
var player: CharacterBody2D
var state: StringName = &"idle"
var timer := 1.0
var attack_index := 0
var target_position := Vector2.ZERO
var indicator: Line2D
var sprite: Sprite2D

func _ready() -> void:
    super._ready()
    sprite = get_node_or_null("Sprite2D") as Sprite2D

func _process(_delta: float) -> void:
    # El Deshonor se acumula hasta cinco veces durante el combate.
    if not is_instance_valid(player): return


func _physics_process(delta: float) -> void:
    if is_dead: return
    if not is_instance_valid(player):
        var found := get_tree().get_first_node_in_group("player")
        if found is CharacterBody2D: player = found
    if not is_instance_valid(player): return
    if state == &"windup":
        timer -= delta
        velocity = Vector2.ZERO
        move_and_slide()
        if timer <= 0.0:
            _execute_attack()
            state = &"idle"
            timer = attack_cooldown
            _clear_indicator()
        return
    if state == &"idle":
        var offset := player.global_position - global_position
        if offset.length() > 105.0:
            velocity = offset.normalized() * movement_speed
            move_and_slide()
            _clamp_room()
        else:
            velocity = Vector2.ZERO
            move_and_slide()
        timer -= delta
        if timer <= 0.0:
            _start_attack()

func _start_attack() -> void:
    state = &"windup"
    timer = 0.8
    target_position = player.global_position
    _show_warning()

func _show_warning() -> void:
    _clear_indicator()
    indicator = Line2D.new()
    indicator.width = 6.0
    indicator.default_color = Color(1.0, 0.85, 0.3, 0.8)
    indicator.z_index = 20
    var pts := PackedVector2Array()
    if attack_index == 0:
        pts.append(global_position + Vector2(-room_half_extents.x, target_position.y-global_position.y))
        pts.append(global_position + Vector2(room_half_extents.x, target_position.y-global_position.y))
    elif attack_index == 1:
        pts.append(global_position + Vector2(target_position.x-global_position.x, -room_half_extents.y))
        pts.append(global_position + Vector2(target_position.x-global_position.x, room_half_extents.y))
    else:
        for i in range(49):
            var a := TAU * float(i)/48.0
            pts.append(global_position + Vector2(cos(a), sin(a))*105.0)
    indicator.points = pts
    get_tree().current_scene.add_child(indicator)

func _execute_attack() -> void:
    if not is_instance_valid(player): return
    var d := player.global_position - global_position
    if attack_index == 0 and absf(player.global_position.y-target_position.y) < 26.0 and absf(d.x) < room_half_extents.x:
        _damage_player(side_damage)
    elif attack_index == 1 and absf(player.global_position.x-target_position.x) < 30.0 and absf(d.y) < room_half_extents.y:
        _damage_player(horizontal_damage)
    elif attack_index == 2 and d.length() < 105.0:
        _damage_player(spin_damage)
    attack_index = (attack_index+1)%3

func _damage_player(amount: int) -> void:
    if not is_instance_valid(player): return
    if player.has_method("take_damage"):
        player.take_damage(amount, global_position)
    # Deshonor: el corte lateral reduce daño y velocidad temporalmente.
    if attack_index == 0:
        var stacks := mini(5, int(player.get_meta("deshonor_stacks", 0)) + 1)
        player.set_meta("deshonor_stacks", stacks)
        if player.get("attack_damage") != null:
            if not player.has_meta("deshonor_damage_original"):
                player.set_meta("deshonor_damage_original", player.get("attack_damage"))
            var original_damage := int(player.get_meta("deshonor_damage_original"))
            player.set("attack_damage", maxi(1, roundi(float(original_damage) * (1.0 - 0.1 * stacks))))
        if player.get("speed") != null:
            if not player.has_meta("deshonor_speed_original"):
                player.set_meta("deshonor_speed_original", player.get("speed"))
            var original_speed := float(player.get_meta("deshonor_speed_original"))
            player.set("speed", original_speed * (1.0 - 0.1 * stacks))
        print("Daynan aplica Deshonor: ", stacks, "/5")

func _clamp_room() -> void:
    if confined_to_room:
        global_position.x = clampf(global_position.x, confined_center_global.x-room_half_extents.x, confined_center_global.x+room_half_extents.x)
        global_position.y = clampf(global_position.y, confined_center_global.y-room_half_extents.y, confined_center_global.y+room_half_extents.y)

func _clear_indicator() -> void:
    if is_instance_valid(indicator): indicator.queue_free()
    indicator = null

func take_damage(amount: int, attacker_position: Vector2 = Vector2.ZERO) -> void:
    super.take_damage(amount, attacker_position)
    queue_redraw()

func _defeat() -> void:
    if is_dead: return
    _clear_indicator()
    super._defeat()
    if is_instance_valid(player):
        if player.has_meta("deshonor_damage_original"):
            player.set("attack_damage", player.get_meta("deshonor_damage_original"))
            player.remove_meta("deshonor_damage_original")
        if player.has_meta("deshonor_speed_original"):
            player.set("speed", player.get_meta("deshonor_speed_original"))
            player.remove_meta("deshonor_speed_original")
        player.remove_meta("deshonor_stacks")
    if sector_type != "": GameData.grant_soul_fragment("Honor")
    GameData.mark_sector_cleared(sector_type)

func _draw() -> void:
    if is_dead: return
    var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(-58, -62), "MINIJEFE: DAYNAN", HORIZONTAL_ALIGNMENT_CENTER, 116, 11, Color("#f5df9b"))
    draw_rect(Rect2(-46, -53, 92, 7), Color("#3d2432"))
    draw_rect(Rect2(-46, -53, 92 * ratio, 7), Color("#d6ad58"))
