extends Node3D
class_name Main

# flow states
const FLOW_TITLE = 0
const FLOW_PLAYING = 1
const FLOW_PAUSED = 2
const FLOW_DEAD = 3

@onready var player_scene: PackedScene = preload("res://scenes/player.tscn")
@onready var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@onready var tile_scene: PackedScene = preload("res://scenes/tile.tscn")

var engine: GameEngine
var state: GameState
var star_systems: StarSystemManager
var ability_sys: AbilitySystem
var combat_sys: CombatSystem
var faction_mgr: FactionManager
var economy: Economy
var bestiary: Bestiary
var codex: Codex
var world_gen: WorldGenerator
var hud: HUD

var current_map: Dictionary = {}
var enemies: Array = []
var tiles: Array = []
var flow: int = FLOW_TITLE

var cam: Camera3D = null
var cam_offset: Vector3 = Vector3(0, 19, 9)
var shake_trauma: float = 0.0
var env: Environment
var world_env: WorldEnvironment
var light: DirectionalLight3D
var gate_check_timer: float = 0.0
var near_gate: bool = false

var overlay_layer: CanvasLayer
var title_screen: Control
var pause_screen: Control
var death_screen: Control
var warp_menu: Control
var warp_button: Button
var banner_label: Label
var warp_vbox: VBoxContainer
var death_shown: bool = false

const BIOME_ENV: Dictionary = {
	"temperate":  {"bg": Color(0.35, 0.5, 0.65), "amb": Color(0.55, 0.6, 0.65), "fog": Color(0.4, 0.5, 0.6),  "fogd": 0.010, "light": Color(1.0, 0.95, 0.85), "le": 1.1},
	"volcanic":   {"bg": Color(0.14, 0.05, 0.05), "amb": Color(0.5, 0.3, 0.25), "fog": Color(0.35, 0.1, 0.05), "fogd": 0.022, "light": Color(1.0, 0.6, 0.4), "le": 0.9},
	"river":      {"bg": Color(0.25, 0.45, 0.55), "amb": Color(0.5, 0.6, 0.65), "fog": Color(0.3, 0.5, 0.55),  "fogd": 0.014, "light": Color(0.95, 1.0, 0.95), "le": 1.05},
	"void":       {"bg": Color(0.04, 0.03, 0.08), "amb": Color(0.35, 0.3, 0.5), "fog": Color(0.15, 0.08, 0.25),"fogd": 0.02, "light": Color(0.6, 0.5, 0.9), "le": 0.7},
	"marsh":      {"bg": Color(0.2, 0.3, 0.2),  "amb": Color(0.45, 0.55, 0.45), "fog": Color(0.25, 0.35, 0.25),"fogd": 0.02, "light": Color(0.85, 0.95, 0.75), "le": 0.85},
	"industrial": {"bg": Color(0.25, 0.22, 0.2), "amb": Color(0.55, 0.5, 0.45), "fog": Color(0.3, 0.26, 0.22), "fogd": 0.016, "light": Color(1.0, 0.85, 0.65), "le": 0.95},
	"crystal":    {"bg": Color(0.12, 0.06, 0.2), "amb": Color(0.5, 0.35, 0.6), "fog": Color(0.25, 0.12, 0.4),  "fogd": 0.016, "light": Color(0.85, 0.7, 1.0), "le": 0.95},
	"barren":     {"bg": Color(0.4, 0.38, 0.35), "amb": Color(0.6, 0.58, 0.55), "fog": Color(0.45, 0.42, 0.4), "fogd": 0.018, "light": Color(1.0, 0.98, 0.9), "le": 1.0},
	"reef":       {"bg": Color(0.15, 0.4, 0.5), "amb": Color(0.45, 0.6, 0.65), "fog": Color(0.2, 0.45, 0.5),   "fogd": 0.016, "light": Color(0.8, 1.0, 0.95), "le": 1.0},
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_init_systems()
	_init_environment()
	_generate_world()
	_spawn_player()
	_spawn_enemies()
	_spawn_item_pickups()
	_init_hud()
	_init_camera()
	_build_overlays()
	_show_title()
	print("[Main] Halcyon Expanse initialized")

func _init_systems():
	engine = $GameEngine
	state = engine.state
	star_systems = $StarSystemManager
	ability_sys = $AbilitySystem
	combat_sys = $CombatSystem
	faction_mgr = $FactionManager
	economy = $Economy
	bestiary = $Bestiary
	codex = $Codex
	world_gen = WorldGenerator.new(randi())

func _init_environment():
	world_env = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	world_env.environment = env
	add_child(world_env)
	light = $DirectionalLight3D
	_apply_biome_env("temperate")

func _apply_biome_env(biome: String):
	var spec = BIOME_ENV.get(biome, BIOME_ENV["temperate"])
	env.background_color = spec["bg"]
	env.ambient_light_color = spec["amb"]
	env.ambient_light_energy = 0.7
	env.fog_light_color = spec["fog"]
	env.fog_density = spec["fogd"]
	if light:
		light.light_color = spec["light"]
		light.light_energy = spec["le"]

func _generate_world():
	var sys_name = star_systems.current_system
	var sys_data = star_systems.get_system_data(sys_name)
	var biome = sys_data.get("biome", "temperate")
	current_map = world_gen.generate_system(sys_name, biome)
	_apply_biome_env(biome)

	for t in tiles:
		if is_instance_valid(t):
			t.queue_free()
	tiles.clear()

	var tile_size = world_gen.tile_size
	for y in range(current_map["height"]):
		for x in range(current_map["width"]):
			var tile_type = current_map["tiles"][y][x]
			var tile = tile_scene.instantiate()
			tile.position = Vector3(x * tile_size, 0, y * tile_size)
			tile.setup(tile_type, biome)
			$World.add_child(tile)
			tiles.append(tile)

func _spawn_player():
	var spawn = current_map["spawn_points"][0]
	var pos = world_gen.grid_to_world(spawn)
	var player = player_scene.instantiate()
	player.position = pos
	$Entities.add_child(player)
	state.add_entity(player)
	player.resonance = "Ember"
	player.attunement = 1
	player.lattice_charge = 500.0

func _spawn_enemies():
	for espawn in current_map.get("enemy_spawns", []):
		if randf() < 0.6:
			var pos = world_gen.grid_to_world(espawn)
			var enemy = enemy_scene.instantiate()
			enemy.position = pos
			var types = ["Ash Wraith", "Hollow Stalker", "Iron Drone", "Tide Serpent", "Chorus Knight", "Swarm Mite"]
			enemy.enemy_type = types[randi() % types.size()]
			var entry = bestiary.get_entry(enemy.enemy_type)
			enemy.hp = entry.get("hp", 80)
			enemy.max_hp = enemy.hp
			enemy.damage = entry.get("damage", 12)
			enemy.behavior_pattern = entry.get("pattern", "phase_cycle")
			if randf() < 0.12:
				enemy.make_elite()
			$Entities.add_child(enemy)
			enemies.append(enemy)
			state.add_entity(enemy)

func _spawn_item_pickups():
	var count = 0
	for ispawn in current_map.get("item_spawns", []):
		if count >= 12:
			break
		Pickup.spawn(self, world_gen.grid_to_world(ispawn), "lc", 80.0)
		count += 1

func _init_hud():
	hud = $HUD
	if state.player:
		hud.set_player(state.player)

func _init_camera():
	var player = state.player
	if player:
		var c = player.get_node_or_null("Camera3D")
		if c:
			player.remove_child(c)
			add_child(c)
			cam = c
	if cam == null:
		cam = Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 20.0
		add_child(cam)
	cam.current = true

func add_shake(amount: float):
	shake_trauma = min(shake_trauma + amount, 1.0)

func _update_camera(delta):
	if cam == null or state.player == null:
		return
	var target = state.player.global_position + cam_offset
	cam.global_position = cam.global_position.lerp(target, 6.0 * delta)
	cam.look_at(state.player.global_position + Vector3(0, 0.5, 0))
	if shake_trauma > 0.001:
		shake_trauma = max(shake_trauma - delta * 1.6, 0.0)
		var s = shake_trauma * shake_trauma * 0.9
		cam.global_position += Vector3(randf_range(-s, s), randf_range(-s, s), randf_range(-s, s))

# ---------------- UI overlays (container-centered, resolution-independent) ----------------

func _mk_full_rect(parent: Node, color: Color) -> ColorRect:
	var r = ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(r)
	return r

func _mk_label(parent: Node, text: String, size: int) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)
	parent.add_child(l)
	return l

func _mk_button(parent: Node, text: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(340, 72)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _mk_screen(tint: Color) -> Dictionary:
	var screen = Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(screen)
	_mk_full_rect(screen, tint)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	center.add_child(vbox)
	return {"screen": screen, "vbox": vbox}

func _build_overlays():
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 20
	overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay_layer)

	var t = _mk_screen(Color(0.04, 0.03, 0.07, 0.92))
	title_screen = t["screen"]
	_mk_label(t["vbox"], "HALCYON EXPANSE", 72)
	_mk_label(t["vbox"], "lattice · resonance · the hollow", 26)
	_mk_button(t["vbox"], "ENTER THE EXPANSE", _on_start_pressed)
	_mk_label(t["vbox"], "stick move · ATK attack · buttons 1-7 abilities · DASH", 18)

	var p = _mk_screen(Color(0.02, 0.02, 0.04, 0.8))
	pause_screen = p["screen"]
	pause_screen.visible = false
	_mk_label(p["vbox"], "PAUSED", 56)
	_mk_button(p["vbox"], "RESUME", _on_resume_pressed)
	_mk_button(p["vbox"], "RESTART SYSTEM", _on_restart_pressed)

	var d = _mk_screen(Color(0.1, 0.02, 0.03, 0.85))
	death_screen = d["screen"]
	death_screen.visible = false
	_mk_label(d["vbox"], "THE HOLLOW TAKES YOU", 52)
	var dl = _mk_label(d["vbox"], "", 26)
	dl.name = "DeathStats"
	_mk_button(d["vbox"], "RISE AGAIN", _on_respawn_pressed)

	var w = _mk_screen(Color(0.02, 0.05, 0.08, 0.85))
	warp_menu = w["screen"]
	warp_menu.visible = false
	warp_vbox = w["vbox"]
	_mk_label(warp_vbox, "SEAM GATE — CHOOSE DESTINATION", 36)

	warp_button = Button.new()
	warp_button.text = "WARP"
	warp_button.add_theme_font_size_override("font_size", 28)
	warp_button.custom_minimum_size = Vector2(240, 70)
	warp_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	warp_button.position = Vector2(-120, -320)
	warp_button.visible = false
	warp_button.pressed.connect(_on_warp_button)
	overlay_layer.add_child(warp_button)

	banner_label = Label.new()
	banner_label.add_theme_font_size_override("font_size", 44)
	banner_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	banner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	banner_label.add_theme_constant_override("shadow_offset_x", 3)
	banner_label.add_theme_constant_override("shadow_offset_y", 3)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner_label.offset_top = 80
	banner_label.offset_bottom = 260
	banner_label.modulate.a = 0.0
	overlay_layer.add_child(banner_label)

func show_banner(text: String, sub: String = ""):
	banner_label.text = text if sub == "" else text + "\n" + sub
	banner_label.modulate.a = 1.0
	var tw = banner_label.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(banner_label, "modulate:a", 0.0, 0.8)

func _show_title():
	flow = FLOW_TITLE
	title_screen.visible = true

func _on_start_pressed():
	title_screen.visible = false
	flow = FLOW_PLAYING
	var biome = current_map.get("biome", "temperate")
	show_banner(star_systems.current_system.to_upper(), biome + " reaches")

func _on_resume_pressed():
	get_tree().paused = false
	pause_screen.visible = false

func _on_restart_pressed():
	get_tree().paused = false
	pause_screen.visible = false
	_restart_system()

func _on_respawn_pressed():
	death_screen.visible = false
	_respawn_player()

func _restart_system():
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for pk in get_tree().get_nodes_in_group("pickups"):
		pk.queue_free()
	_generate_world()
	_spawn_enemies()
	_spawn_item_pickups()
	_respawn_player()

func _respawn_player():
	var p = state.player
	if p == null:
		return
	p.dead = false
	p.hp = p.max_hp
	p.lattice_charge = 300.0
	p.shield_active = false
	var spawn = current_map["spawn_points"][0]
	p.global_position = world_gen.grid_to_world(spawn)
	p.velocity = Vector3.ZERO
	death_shown = false
	flow = FLOW_PLAYING

func _on_warp_button():
	_open_warp_menu()

func _open_warp_menu():
	for ch in warp_vbox.get_children():
		if ch is Button:
			ch.queue_free()
	var targets = star_systems.get_available_warp_targets()
	for t in targets:
		var data = star_systems.get_system_data(t)
		var label = "%s  (%s · danger %d)" % [t, data.get("biome", "?"), data.get("danger", 1)]
		_mk_button(warp_vbox, label, _on_warp_pick.bind(t))
	_mk_button(warp_vbox, "CANCEL", _on_warp_cancel)
	warp_menu.visible = true
	get_tree().paused = true

func _on_warp_pick(target: String):
	warp_menu.visible = false
	get_tree().paused = false
	warp_to_system(target)

func _on_warp_cancel():
	warp_menu.visible = false
	get_tree().paused = false

func _process(delta):
	_update_camera(delta)
	if get_tree().paused:
		if Input.is_action_just_pressed("pause_menu") and not warp_menu.visible:
			_on_resume_pressed()
		return
	if flow != FLOW_PLAYING:
		return
	if state.player == null:
		return

	# pause toggle
	if Input.is_action_just_pressed("pause_menu") and not warp_menu.visible:
		if get_tree().paused:
			_on_resume_pressed()
		else:
			get_tree().paused = true
			pause_screen.visible = true
		return

	var player = state.player

	# player death
	if player.dead and not death_shown:
		death_shown = true
		var dl = death_screen.get_node_or_null("DeathStats")
		if dl:
			dl.text = "level %d · %d kills · system %s" % [player.level, player.kills, star_systems.current_system]
		death_screen.visible = true
		add_shake(0.8)
		return
	if player.dead:
		return

	# enemy behaviour + attacks
	for e in enemies:
		if is_instance_valid(e) and not e.dead:
			e.update(delta, player.global_position)
			if e.global_position.distance_to(player.global_position) < e.attack_range and e.attack_cooldown <= 0:
				e.attack_cooldown = 1.5
				var dmg = combat_sys.enemy_attack(e, player)
				Juice.damage_text(self, player.global_position, str(dmg), Color(1, 0.35, 0.3))
				Juice.burst(self, player.global_position + Vector3(0, 1, 0), Color(1, 0.3, 0.25), 8, 3.5, 0.3, 0.07)
				add_shake(0.3)

	# kill rewards + cleanup
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if not is_instance_valid(e):
			enemies.remove_at(i)
		elif e.dead:
			if not e.xp_awarded:
				e.xp_awarded = true
				player.gain_xp(e.xp_value)
				player.kills += 1
			enemies.remove_at(i)

	# gate proximity → warp prompt
	gate_check_timer -= delta
	if gate_check_timer <= 0:
		gate_check_timer = 0.25
		near_gate = false
		for g in current_map.get("gates", []):
			var gw = world_gen.grid_to_world(g)
			if player.global_position.distance_to(gw) < 3.2:
				near_gate = true
				break
		warp_button.visible = near_gate

	# keyboard gate interaction
	if near_gate and Input.is_action_just_pressed("interact"):
		_open_warp_menu()

func warp_to_system(target: String):
	if star_systems.warp(target):
		for e in enemies:
			if is_instance_valid(e):
				e.queue_free()
		enemies.clear()
		for pk in get_tree().get_nodes_in_group("pickups"):
			pk.queue_free()
		_generate_world()
		_spawn_enemies()
		_spawn_item_pickups()
		if state.player:
			var spawn = current_map["spawn_points"][0]
			state.player.global_position = world_gen.grid_to_world(spawn)
			state.player.velocity = Vector3.ZERO
			Juice.ring(self, state.player.global_position, Color(0.2, 0.8, 1.0), 7.0, 0.7)
			Juice.burst(self, state.player.global_position + Vector3(0, 1, 0), Color(0.3, 0.8, 1.0), 40, 7.0, 0.8, 0.1)
		var data = star_systems.get_system_data(target)
		show_banner(target.to_upper(), data.get("biome", "") + " reaches · danger " + str(data.get("danger", 1)))
