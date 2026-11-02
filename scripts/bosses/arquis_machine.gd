extends Node2D
class_name ArquisMachine

@export var shots_left: int = 3
@export var shot_interval: float = 0.8
@export var projectile_damage: int = 9
@export var projectile_speed: float = 190.0
var player: CharacterBody2D
var timer: float = 0.35

func _ready() -> void:
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([Vector2(-15, -10), Vector2(15, -10), Vector2(19, 9), Vector2(-19, 9)])
    visual.color = Color("#9b83ad")
    add_child(visual)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        var candidate := get_tree().get_first_node_in_group("player")
        if candidate is CharacterBody2D:
            player = candidate as CharacterBody2D
        return
    timer -= delta
    if timer > 0.0:
        return
    timer = shot_interval
    var shot := BossProjectile.new()
    shot.damage = projectile_damage
    shot.velocity = global_position.direction_to(player.global_position) * projectile_speed
    shot.radius = 5.0
    shot.get_node_or_null("Polygon2D")
    get_tree().current_scene.add_child(shot)
    shot.global_position = global_position
    shots_left -= 1
    if shots_left <= 0:
        queue_free()
