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
var weapon_label: Label
var weapon_icon: TextureRect
var buff_label: Label
var cons_labels: Dictionary = {}
var cons_icons: Dictionary = {}
var _last_wid: String = ""
const CONS_META: Dictionary = {"stim": ["STIM", "icon_stim"], "shield": ["AEGIS", "icon_shield"],
	"oc": ["OVERCHARGE", "icon_oc"], "xp": ["XP CORE", "icon_xp"]}

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

	# dark translucent backdrop panel behind the whole stack
	var bg = PanelContainer.new()
	var bg_sb = StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.02, 0.03, 0.06, 0.55)
	bg_sb.corner_radius_top_left = 10
	bg_sb.corner_radius_top_right = 10
	bg_sb.corner_radius_bottom_left = 10
	bg_sb.corner_radius_bottom_right = 10
	bg_sb.content_margin_left = 10
	bg_sb.content_margin_right = 10
	bg_sb.content_margin_top = 8
	bg_sb.content_margin_bottom = 8
	bg.add_theme_stylebox_override("panel", bg_sb)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer.add_child(bg)
	$MarginContainer.move_child(bg, 0)

	# weapon row
	var wrow = HBoxContainer.new()
	weapon_icon = TextureRect.new()
	weapon_icon.custom_minimum_size = Vector2(30, 30)
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wrow.add_child(weapon_icon)
	weapon_label = Label.new()
	weapon_label.add_theme_font_size_override("font_size", 16)
	wrow.add_child(weapon_label)
	vbox.add_child(wrow)

	# active buffs line
	buff_label = Label.new()
	buff_label.add_theme_font_size_override("font_size", 14)
	buff_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(buff_label)

	# consumable pouch with icons + counts
	var crow = HBoxContainer.new()
	for k in ["stim", "shield", "oc", "xp"]:
		var ic = TextureRect.new()
		ic.custom_minimum_size = Vector2(24, 24)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture = load("res://assets/icons/%s.png" % CONS_META[k][1])
		crow.add_child(ic)
		cons_icons[k] = ic
		var lb = Label.new()
		lb.add_theme_font_size_override("font_size", 14)
		crow.add_child(lb)
		cons_labels[k] = lb
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(8, 1)
		crow.add_child(spacer)
	vbox.add_child(crow)
	var hint = Label.new()
	hint.text = "Q/E or USE buttons to consume"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vbox.add_child(hint)

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

	# weapon
	if player.weapon_id != _last_wid:
		_last_wid = player.weapon_id
		var w = WeaponDB.get_w(_last_wid)
		weapon_label.text = w["name"]
		weapon_icon.texture = load("res://assets/icons/%s.png" % w["icon"])
	# buffs
	var buffs = []
	if player.stim_t > 0:
		buffs.append("STIM %.0fs" % player.stim_t)
	if player.oc_t > 0:
		buffs.append("OVERCHARGE %.0fs" % player.oc_t)
	if player.shield_active:
		buffs.append("AEGIS %.0fs" % player.shield_duration)
	buff_label.text = "  ·  ".join(buffs)
	buff_label.visible = buffs.size() > 0
	# consumables
	for k in cons_labels.keys():
		var n = player.consumables.get(k, 0)
		cons_labels[k].text = "x%d" % n
		cons_icons[k].modulate = Color(1, 1, 1) if n > 0 else Color(0.35, 0.35, 0.4)
	stats_label.text = "Kills: %d   Dash: %s" % [player.kills, "READY" if player.dash_cooldown <= 0 else "%.1fs" % player.dash_cooldown]

	var main = get_node_or_null("/root/Main")
	if main and main.star_systems:
		system_label.text = "System: %s | Year: %d | Enemies: %d" % [
			main.star_systems.current_system, main.state.current_year, main.enemies.size()
		]
