extends Node3D
class_name Main

const FLOW_TITLE = 0
const FLOW_PLAYING = 1
const FLOW_PAUSED = 2
const FLOW_DEAD = 3

@onready var player_scene: PackedScene = preload("res://scenes/player.tscn")
@onready var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var engine: GameEngine
var state: GameState
var star_systems: StarSystemManager
var ability_sys: AbilitySystem
var combat_sys: CombatSystem
var faction_mgr: FactionManager
var economy: Economy
var bestiary: Bestiary
var codex: Codex
var terrain: TerrainBuilder
var hud: HUD

var world_info: Dictionary = {}
var current_biome: String = "temperate"
var enemies: Array = []
var flow: int = FLOW_TITLE

# third-person boom camera
var cam: Camera3D = null
var cam_yaw: float = 0.0
var cam_pitch: float = 0.5
var cam_dist: float = 8.5
var shake_trauma: float = 0.0
var env: Environment
var world_env: WorldEnvironment
var light: DirectionalLight3D
var gate_check_timer: float = 0.0
var director_timer: float = 0.0
var bounds_warn_timer: float = 0.0
var near_gate: bool = false

const ENEMY_TARGET: int = 16
const ENEMY_SPAWN_MIN: float = 35.0
const ENEMY_SPAWN_MAX: float = 60.0
const ENEMY_CULL_DIST: float = 110.0
const WORLD_BOUND: float = 112.0

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
	"temperate":  {"sky_t": Color(0.25, 0.45, 0.75), "sky_h": Color(0.65, 0.75, 0.85), "gnd": Color(0.2, 0.25, 0.2), "amb": Color(0.55, 0.6, 0.65), "fog": Color(0.4, 0.5, 0.6), "fogd": 0.0045, "light": Color(1.0, 0.95, 0.85), "le": 1.1},
	"volcanic":   {"sky_t": Color(0.12, 0.03, 0.03), "sky_h": Color(0.6, 0.2, 0.08), "gnd": Color(0.1, 0.05, 0.04), "amb": Color(0.5, 0.3, 0.25), "fog": Color(0.35, 0.1, 0.05), "fogd": 0.009, "light": Color(1.0, 0.6, 0.4), "le": 0.9},
	"river":      {"sky_t": Color(0.2, 0.4, 0.6), "sky_h": Color(0.55, 0.75, 0.8), "gnd": Color(0.15, 0.25, 0.25), "amb": Color(0.5, 0.6, 0.65), "fog": Color(0.3, 0.5, 0.55), "fogd": 0.006, "light": Color(0.95, 1.0, 0.95), "le": 1.05},
	"void":       {"sky_t": Color(0.02, 0.01, 0.05), "sky_h": Color(0.25, 0.1, 0.4), "gnd": Color(0.05, 0.03, 0.1), "amb": Color(0.35, 0.3, 0.5), "fog": Color(0.15, 0.08, 0.25), "fogd": 0.008, "light": Color(0.6, 0.5, 0.9), "le": 0.7},
	"marsh":      {"sky_t": Color(0.15, 0.25, 0.2), "sky_h": Color(0.45, 0.55, 0.4), "gnd": Color(0.1, 0.15, 0.1), "amb": Color(0.45, 0.55, 0.45), "fog": Color(0.25, 0.35, 0.25), "fogd": 0.008, "light": Color(0.85, 0.95, 0.75), "le": 0.85},
	"industrial": {"sky_t": Color(0.2, 0.18, 0.16), "sky_h": Color(0.6, 0.45, 0.3), "gnd": Color(0.15, 0.13, 0.12), "amb": Color(0.55, 0.5, 0.45), "fog": Color(0.3, 0.26, 0.22), "fogd": 0.007, "light": Color(1.0, 0.85, 0.65), "le": 0.95},
	"crystal":    {"sky_t": Color(0.08, 0.04, 0.16), "sky_h": Color(0.45, 0.2, 0.65), "gnd": Color(0.1, 0.05, 0.18), "amb": Color(0.5, 0.35, 0.6), "fog": Color(0.25, 0.12, 0.4), "fogd": 0.006, "light": Color(0.85, 0.7, 1.0), "le": 0.95},
	"barren":     {"sky_t": Color(0.35, 0.33, 0.3), "sky_h": Color(0.7, 0.65, 0.55), "gnd": Color(0.25, 0.23, 0.2), "amb": Color(0.6, 0.58, 0.55), "fog": Color(0.45, 0.42, 0.4), "fogd": 0.007, "light": Color(1.0, 0.98, 0.9), "le": 1.0},
	"reef":       {"sky_t": Color(0.1, 0.3, 0.45), "sky_h": Color(0.4, 0.7, 0.75), "gnd": Color(0.1, 0.25, 0.3), "amb": Color(0.45, 0.6, 0.65), "fog": Color(0.2, 0.45, 0.5), "fogd": 0.006, "light": Color(0.8, 1.0, 0.95), "le": 1.0},
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_init_systems()
	_init_environment()
	_build_world()
	_spawn_player()
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

func _init_environment():
	world_env = WorldEnvironment.new()
	env = Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.08
	world_env.environment = env
	add_child(world_env)
	light = $DirectionalLight3D
	_apply_biome_env("temperate")

func _apply_biome_env(biome: String):
	var spec = BIOME_ENV.get(biome, BIOME_ENV["temperate"])
	var sky = Sky.new()
	var sm = ProceduralSkyMaterial.new()
	sm.sky_top_color = spec["sky_t"]
	sm.sky_horizon_color = spec["sky_h"]
	sm.ground_bottom_color = spec["gnd"]
	sm.ground_horizon_color = spec["sky_h"]
	sm.sun_angle_max = 25.0
	sm.sky_curve = 0.08
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_color = spec["amb"]
	env.ambient_light_energy = 0.7
	env.fog_light_color = spec["fog"]
	env.fog_density = spec["fogd"]
	if light:
		light.light_color = spec["light"]
		light.light_energy = spec["le"]

# ---------------- open world ----------------

func _build_world():
	for t in get_tree().get_nodes_in_group("terrain"):
		t.queue_free()
	var sys_name = star_systems.current_system
	var sys_data = star_systems.get_system_data(sys_name)
	current_biome = sys_data.get("biome", "temperate")
	terrain = TerrainBuilder.new(randi())
	world_info = terrain.build(self, current_biome)
	_apply_biome_env(current_biome)
	for ipos in world_info.get("items", []):
		Pickup.spawn(self, ipos, "lc", 80.0)

func _spawn_player():
	var player = player_scene.instantiate()
	player.position = world_info["spawn"]
	$Entities.add_child(player)
	state.add_entity(player)
	player.resonance = "Ember"
	player.attunement = 1
	player.lattice_charge = 500.0

func _spawn_enemy_at(pos: Vector3) -> Enemy:
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
	return enemy

func _enemy_director():
	if state.player == null:
		return
	var pp = state.player.global_position
	# cull far
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if not is_instance_valid(e):
			enemies.remove_at(i)
		elif e.global_position.distance_to(pp) > ENEMY_CULL_DIST:
			e.queue_free()
			state.remove_entity(e)
			enemies.remove_at(i)
	# spawn to target density
	var deficit = ENEMY_TARGET - enemies.size()
	for i in range(min(deficit, 3)):
		var a = randf() * TAU
		var d = randf_range(ENEMY_SPAWN_MIN, ENEMY_SPAWN_MAX)
		var x = clamp(pp.x + sin(a) * d, -WORLD_BOUND, WORLD_BOUND)
		var z = clamp(pp.z + cos(a) * d, -WORLD_BOUND, WORLD_BOUND)
		_spawn_enemy_at(Vector3(x, terrain.height_at(x, z) + 1.2, z))

func _init_hud():
	hud = $HUD
	if state.player:
		hud.set_player(state.player)

func _init_camera():
	var player = state.player
	if player:
		var c = player.get_node_or_null("Camera3D")
		if c:
			c.queue_free()
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.current = true
	add_child(cam)
	if player:
		cam_yaw = 0.0
		cam.global_position = player.global_position + Vector3(0, 4, 8)

func get_cam_forward() -> Vector3:
	return Vector3(-sin(cam_yaw), 0, -cos(cam_yaw)).normalized()

func add_shake(amount: float):
	shake_trauma = min(shake_trauma + amount, 1.0)

func hit_stop(dur: float = 0.06, scale: float = 0.15):
	Engine.time_scale = scale
	await get_tree().create_timer(dur, true, false, true).timeout
	if not get_tree().paused:
		Engine.time_scale = 1.0

func zoom_punch(amount: float = 8.0, dur: float = 0.4):
	if cam == null:
		return
	var tw = cam.create_tween()
	tw.tween_property(cam, "fov", 70.0 - amount, dur * 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "fov", 70.0, dur * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _update_camera(delta):
	if cam == null or state.player == null:
		return
	# consume look input (right-half touch drag / desktop right-drag)
	var mc = get_node_or_null("HUD/MobileControls")
	if mc:
		var ld = mc.consume_look_delta()
		cam_yaw -= ld.x * 0.006
		cam_pitch = clamp(cam_pitch + ld.y * 0.0045, -0.1, 1.15)
	var pivot = state.player.global_position + Vector3(0, 1.7, 0)
	var off = Vector3(sin(cam_yaw) * cos(cam_pitch), sin(cam_pitch), cos(cam_yaw) * cos(cam_pitch)) * cam_dist
	var desired = pivot + off
	# pull in when terrain/props block the view
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pivot, desired, 1)
	var hit = space.intersect_ray(query)
	if hit:
		desired = pivot + (hit["position"] - pivot) * 0.85
	cam.global_position = cam.global_position.lerp(desired, min(12.0 * delta, 1.0))
	cam.look_at(pivot)
	if shake_trauma > 0.001:
		shake_trauma = max(shake_trauma - delta * 1.6, 0.0)
		var s = shake_trauma * shake_trauma * 0.5
		cam.global_position += Vector3(randf_range(-s, s), randf_range(-s, s), randf_range(-s, s))

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		cam_yaw -= event.relative.x * 0.005
		cam_pitch = clamp(cam_pitch + event.relative.y * 0.004, -0.1, 1.15)

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
	show_banner(star_systems.current_system.to_upper(), current_biome + " reaches")

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
	_build_world()
	_respawn_player()

func _respawn_player():
	var p = state.player
	if p == null:
		return
	p.dead = false
	p.hp = p.max_hp
	p.lattice_charge = 300.0
	p.shield_active = false
	p.global_position = world_info["spawn"]
	p.velocity = Vector3.ZERO
	p.vy = 0.0
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

	if Input.is_action_just_pressed("pause_menu") and not warp_menu.visible:
		get_tree().paused = true
		pause_screen.visible = true
		return

	var player = state.player

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

	# world bounds — the Hollow thickens
	var pd = Vector2(player.global_position.x, player.global_position.z).length()
	if pd > WORLD_BOUND:
		var back = Vector3(player.global_position.x, 0, player.global_position.z).normalized()
		player.global_position -= back * (pd - WORLD_BOUND)
		bounds_warn_timer -= delta
		if bounds_warn_timer <= 0:
			bounds_warn_timer = 6.0
			show_banner("THE HOLLOW THICKENS", "turn back")

	# enemy behaviour + attacks
	for e in enemies:
		if is_instance_valid(e) and not e.dead:
			e.update(delta, player.global_position)
			if e.global_position.distance_to(player.global_position) < e.attack_range and e.attack_cooldown <= 0:
				e.attack_cooldown = 1.5
				var dmg = combat_sys.enemy_attack(e, player)
				if dmg > 0:
					Juice.damage_text(self, player.global_position, str(dmg), Color(1, 0.35, 0.3))
					Juice.burst(self, player.global_position + Vector3(0, 1, 0), Color(1, 0.3, 0.25), 8, 3.5, 0.3, 0.07)
					add_shake(0.3)

	# enemy separation (soft-body crowd, no stacking)
	for i2 in range(enemies.size()):
		var a = enemies[i2]
		if not is_instance_valid(a) or a.dead:
			continue
		for j2 in range(i2 + 1, enemies.size()):
			var b2 = enemies[j2]
			if not is_instance_valid(b2) or b2.dead:
				continue
			var d = a.global_position - b2.global_position
			d.y = 0
			var dd = d.length()
			if dd > 0.001 and dd < 1.3:
				var push = d.normalized() * (1.3 - dd) * 3.0 * delta
				a.global_position += push
				b2.global_position -= push

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
				if e.is_elite:
					hit_stop(0.1, 0.08)
					zoom_punch(10.0, 0.4)
			enemies.remove_at(i)

	# enemy director keeps the world populated
	director_timer -= delta
	if director_timer <= 0:
		director_timer = 1.2
		_enemy_director()

	# gate proximity → warp prompt
	gate_check_timer -= delta
	if gate_check_timer <= 0:
		gate_check_timer = 0.25
		near_gate = false
		for g in world_info.get("gates", []):
			if player.global_position.distance_to(g) < 4.5:
				near_gate = true
				break
		warp_button.visible = near_gate
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
		_build_world()
		if state.player:
			state.player.global_position = world_info["spawn"]
			state.player.velocity = Vector3.ZERO
			state.player.vy = 0.0
			Juice.ring(self, state.player.global_position, Color(0.2, 0.8, 1.0), 7.0, 0.7)
			Juice.burst(self, state.player.global_position + Vector3(0, 1, 0), Color(0.3, 0.8, 1.0), 40, 7.0, 0.8, 0.1)
		var data = star_systems.get_system_data(target)
		show_banner(target.to_upper(), data.get("biome", "") + " reaches · danger " + str(data.get("danger", 1)))
