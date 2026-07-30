extends CanvasLayer
class_name HUD

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var lc_bar: ProgressBar = $MarginContainer/VBoxContainer/LCBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/Label
@onready var lc_label: Label = $MarginContainer/VBoxContainer/LCBar/Label
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var system_label: Label = $MarginContainer/VBoxContainer/SystemLabel

var player: PlayerController = null

func _ready():
	pass

func set_player(p: PlayerController):
	player = p

func _process(delta):
	if player == null or player.dead:
		return
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	hp_label.text = "HP: %d/%d" % [player.hp, player.max_hp]

	lc_bar.max_value = player.lattice_charge_max()
	lc_bar.value = player.lattice_charge
	lc_label.text = "LC: %.0f/%.0f" % [player.lattice_charge, player.lattice_charge_max()]

	info_label.text = "Resonance: %s | Attunement: %d | Debt: %.2f" % [
		player.resonance, player.attunement, player.lattice_debt
	]

	var main = get_node_or_null("/root/Main")
	if main and main.star_systems:
		system_label.text = "System: %s | Year: %d" % [
			main.star_systems.current_system, main.state.current_year
		]
