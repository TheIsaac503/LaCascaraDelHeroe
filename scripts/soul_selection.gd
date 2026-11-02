
extends Control

var selected: String = ""

var descriptions := {
	"Ira": "Fragmento inicial: +15% de daño y +10% adicional con media vida o menos.",
	"Bondad": "Fragmento inicial: +10 de vida máxima. Sus pociones curan y aceleran tus ataques.",
	"Orgullo": "Fragmento inicial: +10% de daño y acumula un pequeño bono si pasas tiempo sin recibir daño.",
	"Honor": "Fragmento inicial: +2 de daño y reduce un 15% el daño recibido.",
	"Hermandad": "Fragmento inicial: +10 de vida máxima y un escudo que bloquea un golpe cada 10 segundos.",
	"Creatividad": "Fragmento inicial: +2 de daño y +10% de daño total.",
	"Amor": "Aumenta tu autosanacion y regeneracion de vida en un 20%."
}

var description_label: Label
var confirm_button: Button

func _ready() -> void:
	selected = ""
	_build_interface()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#171c2b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	var title := Label.new()
	title.text = "ELIGE TU FRAGMENTO DE ALMA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Esta eleccion definira tu forma de luchar."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(grid)

	for fragment in descriptions.keys():
		var button := Button.new()
		button.text = fragment
		button.custom_minimum_size = Vector2(130, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_fragment.bind(fragment))
		grid.add_child(button)

	description_label = Label.new()
	description_label.text = "Selecciona uno de los siete fragmentos."
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.custom_minimum_size = Vector2(0, 70)
	layout.add_child(description_label)

	confirm_button = Button.new()
	confirm_button.text = "Confirmar fragmento"
	confirm_button.custom_minimum_size = Vector2(0, 55)
	confirm_button.disabled = true
	confirm_button.pressed.connect(_confirm_selection)
	layout.add_child(confirm_button)

func _select_fragment(fragment: String) -> void:
	selected = fragment
	description_label.text = fragment + "\n" + descriptions[fragment]
	confirm_button.disabled = false

func _confirm_selection() -> void:
	if selected == "":
		return

	GameData.choose_fragment(selected)
	get_tree().change_scene_to_file(
        "res://scenes/dungeon/Prison.tscn"
	)
