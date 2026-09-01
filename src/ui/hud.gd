extends CanvasLayer
class_name HUD

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var lc_bar: ProgressBar = $MarginContainer/VBoxContainer/LCBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/Label
@onready var lc_label: Label = $MarginContainer/VBoxContainer/LCBar/Label
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var system_label: Label = $MarginContainer/VBoxContainer/SystemLabel
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer

var player: PlayerController = null
var xp_bar: ProgressBar
var xp_label: Label
var stats_label: Label

func _ready():
	# keep the status panel a fixed width instead of stretching full screen
	var mc = $MarginContainer
	mc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mc.position = Vector2(10, 10)
	mc.custom_minimum_size = Vector2(430, 0)
	# build XP bar + stats row in code (scene stays untouched)
	xp_bar = ProgressBar.new()
	xp_bar.max_value = 100.0
	xp_bar.value = 0.0
	xp_bar.custom_minimum_size = Vector2(220, 26)
	xp_label = Label.new()
	xp_label.text = "XP"
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_bar.add_child(xp_label)
	vbox.add_child(xp_bar)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stats_label)

	# bar styling
	_style_bar(hp_bar, Color(0.75, 0.15, 0.15), Color(0.15, 0.05, 0.05))
	_style_bar(lc_bar, Color(0.15, 0.6, 0.85), Color(0.05, 0.12, 0.16))
	_style_bar(xp_bar, Color(0.9, 0.75, 0.2), Color(0.18, 0.14, 0.05))
	hp_bar.custom_minimum_size = Vector2(220, 26)
	lc_bar.custom_minimum_size = Vector2(220, 26)

func _style_bar(bar: ProgressBar, fill: Color, bg: Color):
	var fill_sb = StyleBoxFlat.new()
	fill_sb.bg_color = fill
	fill_sb.corner_radius_top_left = 4
	fill_sb.corner_radius_top_right = 4
	fill_sb.corner_radius_bottom_left = 4
	fill_sb.corner_radius_bottom_right = 4
	var bg_sb = StyleBoxFlat.new()
	bg_sb.bg_color = bg
	bg_sb.corner_radius_top_left = 4
	bg_sb.corner_radius_top_right = 4
	bg_sb.corner_radius_bottom_left = 4
	bg_sb.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_sb)
	bar.add_theme_stylebox_override("background", bg_sb)

func set_player(p: PlayerController):
	player = p

func _process(delta):
	if player == null:
		return
	visible = not player.dead
	if player.dead:
		return
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	hp_label.text = "HP: %d/%d" % [player.hp, player.max_hp]

	lc_bar.max_value = player.lattice_charge_max()
	lc_bar.value = player.lattice_charge
	lc_label.text = "LC: %.0f/%.0f" % [player.lattice_charge, player.lattice_charge_max()]

	xp_bar.max_value = player.xp_next()
	xp_bar.value = player.xp
	xp_label.text = "LV %d · XP %d/%d" % [player.level, player.xp, player.xp_next()]

	info_label.text = "Resonance: %s | Attunement: %d" % [player.resonance, player.attunement]
	stats_label.text = "Kills: %d   Dash: %s" % [player.kills, "READY" if player.dash_cooldown <= 0 else "%.1fs" % player.dash_cooldown]

	var main = get_node_or_null("/root/Main")
	if main and main.star_systems:
		system_label.text = "System: %s | Year: %d | Enemies: %d" % [
			main.star_systems.current_system, main.state.current_year, main.enemies.size()
		]
