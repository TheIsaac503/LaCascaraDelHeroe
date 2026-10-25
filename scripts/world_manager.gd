extends Node2D

func _ready() -> void:
	# Se ejecuta automáticamente al iniciar la escena
	_configure_active_sectors()

func _configure_active_sectors() -> void:
	var chosen_fragment := GameData.selected_fragment
	print("Fragmento elegido por el jugador: ", chosen_fragment)
	print("Desactivando el sector y minijefe correspondiente...")
	
	# Busca todos los nodos que pertenezcan al grupo "sectors"
	for sector in get_tree().get_nodes_in_group("sectors"):
		# Si el nombre del sector coincide con el fragmento elegido, se elimina
		if sector.name.begins_with(chosen_fragment):
			print("Eliminando sector no disponible: ", sector.name)
			sector.queue_free()
