extends Node

var selected_fragment: String = "Amor"
var active_bosses: Dictionary = {} # Guarda la lista de minijefes de la partida
var available_boss_fragments: Array[String] = []

# Control del flujo de historia y cinemática inicial
var intro_completed: bool = false 

# Registros de elecciones morales y equipamiento
var amy_spared := false # Si perdonó a Amy (otorga vida extra contra La Oscuridad)
var spared_bosses: Array[String] = []
var brotherhood_set_pieces: Array[String] = []

const BOSS_MAPPING := {
	"Ira": "Radius",
	"Bondad": "Acalenia",
	"Orgullo": "Srbos",
	"Honor": "Daynan",
	"Hermandad": "Anclis",
	"Creatividad": "Arquis",
	"Amor": "Amy"
}

func select_player_fragment(fragment_name: String) -> void:
	selected_fragment = fragment_name
	active_bosses.clear()
	
	# Generar los 6 minijefes y sus sectores excluyendo el fragmento de Isaac
	for fragment in BOSS_MAPPING.keys():
		if fragment == fragment_name:
			continue # Su sector y su minijefe NO existen en esta partida
			
		var boss_name: String = BOSS_MAPPING[fragment]
		
		# Regla especial de Daynan / Radius
		if fragment == "Ira" and fragment_name == "Honor":
			boss_name = "Daynan"
			
		active_bosses[fragment] = boss_name

func reset_game() -> void:
	selected_fragment = "Amor"
	active_bosses.clear()
	available_boss_fragments.clear()
	intro_completed = false
	amy_spared = false
	spared_bosses.clear()
	brotherhood_set_pieces.clear()

func choose_fragment(fragment_name: String) -> void:
	selected_fragment = fragment_name
	active_bosses.clear()
	available_boss_fragments.clear()
	
	# Guardar minijefes activos excluyendo el alma seleccionada por Isaac
	for fragment in BOSS_MAPPING.keys():
		if fragment == fragment_name:
			continue # Su sector y minijefe no existen en esta partida
			
		var boss_name: String = BOSS_MAPPING[fragment]
		
		# Regla especial de Daynan / Radius si se elige Honor
		if fragment == "Ira" and fragment_name == "Honor":
			boss_name = "Daynan"
			
		active_bosses[fragment] = boss_name
		available_boss_fragments.append(fragment)
		
	available_boss_fragments.shuffle()
