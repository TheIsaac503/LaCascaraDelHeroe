extends Area2D
class_name BossProjectile

@export var damage: int = 14
@export var velocity: Vector2 = Vector2.ZERO
@export var fall_gravity: float = 0.0
@export var lifetime: float = 5.0
@export var radius: float = 8.0
var age: float = 0.0
var spent: bool = false

func _ready() -> void:
    collision_layer = 0
    collision_mask = 3
    var shape_node := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = radius
    shape_node.shape = shape
    add_child(shape_node)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)])
    visual.color = Color("#e2a7f0")
    add_child(visual)
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    age += delta
    if age >= lifetime:
        queue_free()
        return
    velocity.y += fall_gravity * delta
    global_position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
    if spent or not body.is_in_group("player"):
        return
    spent = true
    if body.has_method("take_damage"):
        body.take_damage(damage, global_position)
    queue_free()
