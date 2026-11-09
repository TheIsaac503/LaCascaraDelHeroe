extends Node2D

const BOSS_SCENES := [
	preload("res://scenes/entities/bosses/Acalenia.tscn"),
	preload("res://scenes/entities/bosses/Amy.tscn"),
	preload("res://scenes/entities/bosses/Anclis.tscn"),
	preload("res://scenes/entities/bosses/Arquis.tscn"),
	preload("res://scenes/entities/bosses/Daynan.tscn"),
	preload("res://scenes/entities/bosses/Radius.tscn"),
	preload("res://scenes/entities/bosses/Srbos.tscn")
]

const BOSS_NAMES := ["Acalenia", "Amy", "Anclis", "Arquis", "Daynan", "Radius", "Srbos"]

@export_range(0, 6) var starting_boss: int = 0
@export var boss_spawn_position := Vector2(230.0, 0.0)
@export var player_spawn_position := Vector2(-220.0, 0.0)

@onready var boss_container: Node2D = $BossContainer
@onready var isaac: CharacterBody2D = $Isaac
@onready var boss_label: Label = $HUD/BossLabel

var current_boss: Node2D
var current_index: int = 0

func _ready() -> void:
	current_index = starting_boss
	isaac.position = player_spawn_position
	spawn_boss(current_index)

func spawn_boss(index: int) -> void:
	index = clampi(index, 0, BOSS_SCENES.size() - 1)
	if is_instance_valid(current_boss):
		current_boss.queue_free()
		await get_tree().process_frame

	current_index = index
	current_boss = BOSS_SCENES[current_index].instantiate() as Node2D
	boss_container.add_child(current_boss)
	current_boss.global_position = boss_spawn_position
	boss_label.text = "MINIJEFE: %s  |  1-7 cambiar  |  R reiniciar" % BOSS_NAMES[current_index]

func reset_test() -> void:
	isaac.global_position = player_spawn_position
	if "is_dead" in isaac:
		isaac.is_dead = false
	if "is_dashing" in isaac:
		isaac.is_dashing = false
	if "health" in isaac and "max_health" in isaac:
		isaac.health = isaac.max_health
	if isaac.has_method("_play") and isaac.has_method("_idle_name"):
		isaac.call("_play", isaac.call("_idle_name"))
	spawn_boss(current_index)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: spawn_boss(0)
			KEY_2: spawn_boss(1)
			KEY_3: spawn_boss(2)
			KEY_4: spawn_boss(3)
			KEY_5: spawn_boss(4)
			KEY_6: spawn_boss(5)
			KEY_7: spawn_boss(6)
			KEY_R: reset_test()
