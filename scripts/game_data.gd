
extends Node

# Fragmento que conserva Isaac.
var selected_fragment: String = ""

# Estadísticas base del protagonista.
var base_max_health: int = 100
var base_attack_damage: int = 20
var base_attack_cooldown: float = 0.35

# Indica si ya se completó la introducción.
var intro_completed: bool = false

func choose_fragment(fragment: String) -> void:
	selected_fragment = fragment

func reset_game() -> void:
	selected_fragment = ""
	intro_completed = false
