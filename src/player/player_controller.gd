extends Actor
class_name PlayerController

@export var speed: float = 6.0
@export var rotation_speed: float = 10.0

var combat: CombatSystem = null
var ability_sys: AbilitySystem = null
var attack_cooldown: float = 0.0
var ability_cooldowns: Dictionary = {}
var facing: Vector3 = Vector3.FORWARD
var mobile_controls: MobileControls = null
var level: int = 1
var kills: int = 0
var dash_cooldown: float = 0.0
var dash_time: float = 0.0
var dash_dir: Vector3 = Vector3.ZERO
var shield_bubble: MeshInstance3D = null
var vy: float = 0.0
var ghost_timer: float = 0.0
var breathe_t: float = 0.0

const GRAVITY: float = 22.0
const DASH_SPEED: float = 18.0
const DASH_DURATION: float = 0.22
const DASH_CD: float = 1.6
const ABILITY_IDS: Array = ["ember_strike", "gale_dash", "hollow_drain", "tide_heal",
					"root_bind", "iron_shield", "chorus_blast"]
const ABILITY_CDS: Dictionary = {"ember_strike": 3.0, "gale_dash": 4.0, "hollow_drain": 8.0,
					"tide_heal": 10.0, "root_bind": 7.0, "iron_shield": 12.0, "chorus_blast": 15.0}
const ABILITY_COLORS: Dictionary = {"ember_strike": Color(1.0, 0.45, 0.1), "gale_dash": Color(0.5, 0.8, 1.0),
					"hollow_drain": Color(0.6, 0.2, 0.9), "tide_heal": Color(0.2, 0.8, 0.9),
					"root_bind": Color(0.3, 0.8, 0.3), "iron_shield": Color(0.7, 0.7, 0.75),
					"chorus_blast": Color(1.0, 0.9, 0.2)}

func xp_next() -> int:
	return 80 + level * 70

func _ready():
	floor_snap_length = 0.4
	is_player = true
	name = "Player"
	add_to_group("player")
	var main = get_node_or_null("/root/Main")
	if main:
		combat = main.get_node_or_null("CombatSystem")
		ability_sys = main.get_node_or_null("AbilitySystem")
		mobile_controls = main.get_node_or_null("HUD/MobileControls")
	_restyle()

func _restyle():
	var mi = get_node_or_null("MeshInstance3D")
	if mi:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.35, 0.1)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.3, 0.05)
		mat.emission_energy_multiplier = 0.8
		mat.metallic = 0.3
		mat.roughness = 0.5
		mi.material_override = mat
		_add_model_parts(mi)

func _add_model_parts(mi: MeshInstance3D):
	# visor
	var visor = MeshInstance3D.new()
	var vb = BoxMesh.new()
	vb.size = Vector3(0.55, 0.16, 0.1)
	visor.mesh = vb
	var vm = StandardMaterial3D.new()
	vm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vm.albedo_color = Color(0.4, 0.95, 1.0)
	vm.emission_enabled = true
	vm.emission = Color(0.3, 0.9, 1.0)
	vm.emission_energy_multiplier = 2.5
	visor.material_override = vm
	mi.add_child(visor)
	visor.position = Vector3(0, 0.55, 0.42)
	# lattice trim ring at the waist
	var ring = MeshInstance3D.new()
	var tr = TorusMesh.new()
	tr.inner_radius = 0.5
	tr.outer_radius = 0.62
	tr.rings = 24
	tr.ring_segments = 6
	ring.mesh = tr
	var rm = StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.6, 0.15)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.5, 0.1)
	rm.emission_energy_multiplier = 1.8
	ring.material_override = rm
	mi.add_child(ring)
	ring.position = Vector3(0, -0.1, 0)
	ring.rotation.x = PI / 2

func _is_playing() -> bool:
	var main = get_node_or_null("/root/Main")
	return main == null or main.flow == 1

func _physics_process(delta):
	if dead or not _is_playing():
		return
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_abilities(delta)
	attack_cooldown -= delta
	dash_cooldown -= delta
	for k in ability_cooldowns.keys():
		ability_cooldowns[k] -= delta
	_update_shield_bubble()

func _handle_movement(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if mobile_controls and mobile_controls.joystick_active:
		input_dir.x += mobile_controls.joystick_vector.x
		input_dir.z += mobile_controls.joystick_vector.y

	if Input.is_action_just_pressed("dash"):
		do_dash()

	# gravity / floor snap
	if is_on_floor():
		vy = -0.5
	else:
		vy -= GRAVITY * delta

	if dash_time > 0:
		dash_time -= delta
		velocity = Vector3(dash_dir.x * DASH_SPEED, vy, dash_dir.z * DASH_SPEED)
		move_and_slide()
		ghost_timer -= delta
		if ghost_timer <= 0:
			ghost_timer = 0.045
			_spawn_dash_ghost()
		return

	var planar = Vector3.ZERO
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		facing = input_dir
		planar = input_dir * speed
		var mi = get_node_or_null("MeshInstance3D")
		if mi:
			mi.rotation.y = lerp_angle(mi.rotation.y, atan2(facing.x, facing.z), 12.0 * delta)
	velocity = Vector3(planar.x, vy, planar.z)
	move_and_slide()

	# breathing idle
	var mi2 = get_node_or_null("MeshInstance3D")
	if mi2:
		breathe_t += delta * 2.0
		var s = 1.0 + sin(breathe_t) * 0.02
		mi2.scale = Vector3(s, 2.0 - s, s)

func _spawn_dash_ghost():
	var main = get_node_or_null("/root/Main")
	if main == null:
		return
	var g = MeshInstance3D.new()
	var cp = CapsuleMesh.new()
	cp.radius = 0.5
	cp.height = 2.0
	g.mesh = cp
	var gm = StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color = Color(0.5, 0.8, 1.0, 0.35)
	gm.emission_enabled = true
	gm.emission = Color(0.4, 0.7, 1.0)
	g.material_override = gm
	main.add_child(g)
	g.global_position = global_position + Vector3(0, 1.0, 0)
	g.rotation.y = atan2(facing.x, facing.z)
	var tw = g.create_tween()
	tw.tween_property(gm, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(g.queue_free)

func do_dash() -> bool:
	if dash_cooldown > 0 or dead:
		return false
	dash_cooldown = DASH_CD
	dash_time = DASH_DURATION
	dash_dir = facing.normalized() if facing.length() > 0 else Vector3.FORWARD
	var main = get_node_or_null("/root/Main")
	if main:
		Juice.burst(main, global_position + Vector3(0, 0.8, 0), Color(0.5, 0.8, 1.0), 12, 3.0, 0.3, 0.07)
	return true

func _handle_combat(delta):
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0:
		attack_cooldown = 0.45
		_perform_melee_attack()

func _perform_melee_attack():
	var main = get_node_or_null("/root/Main")
	_attack_arc_visual()
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_any = false
	for e in enemies:
		if e.dead:
			continue
		var to_e = e.global_position - global_position
		to_e.y = 0
		var dist = to_e.length()
		if dist > 0.01 and dist < 3.0 and facing.angle_to(to_e.normalized()) < 1.2:
			var dmg = combat.melee_attack(self, e) if combat else 18
			e.apply_knockback(to_e.normalized(), 7.0, 2.0)
			hit_any = true
			if main:
				Juice.damage_text(main, e.global_position, str(dmg), Color(1, 0.9, 0.3))
				Juice.burst(main, e.global_position + Vector3(0, 1, 0), Color(1, 0.6, 0.2), 10, 4.0, 0.35, 0.07)
	if hit_any and main:
		main.add_shake(0.25)

func _attack_arc_visual():
	var main = get_node_or_null("/root/Main")
	if main == null:
		return
	var mi = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 2.2
	torus.outer_radius = 3.0
	torus.rings = 24
	torus.ring_segments = 8
	mi.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.6, 0.15, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.1)
	mi.material_override = mat
	main.add_child(mi)
	mi.global_position = global_position + Vector3(0, 0.8, 0)
	mi.rotation.y = atan2(facing.x, facing.z)
	mi.scale = Vector3(0.3, 1, 0.3)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(1, 1, 1), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(mi.queue_free)

func _handle_abilities(delta):
	for i in range(ABILITY_IDS.size()):
		if Input.is_action_just_pressed("ability_%d" % (i + 1)):
			cast_ability(ABILITY_IDS[i])

func cast_ability(aid: String) -> bool:
	if ability_sys == null:
		return false
	if ability_cooldowns.get(aid, 0.0) > 0:
		return false
	if ability_sys.cast(aid, self):
		ability_cooldowns[aid] = ABILITY_CDS.get(aid, 3.0)
		var main = get_node_or_null("/root/Main")
		if main:
			Juice.burst(main, global_position + Vector3(0, 1.2, 0), ABILITY_COLORS.get(aid, Color.WHITE), 18, 4.0, 0.5, 0.08)
		return true
	else:
		var main2 = get_node_or_null("/root/Main")
		if main2:
			Juice.damage_text(main2, global_position, "NO LC", Color(0.6, 0.6, 0.7))
		return false

func gain_xp(amount: int):
	xp += amount
	while xp >= xp_next():
		xp -= xp_next()
		level += 1
		max_hp += 12
		hp = min(hp + 30, max_hp)
		var main = get_node_or_null("/root/Main")
		if main:
			Juice.ring(main, global_position, Color(1.0, 0.85, 0.2), 5.0, 0.6)
			Juice.burst(main, global_position + Vector3(0, 1, 0), Color(1.0, 0.9, 0.3), 36, 6.0, 0.8, 0.1)
			main.show_banner("LEVEL %d" % level, "max HP up, wounds mended")
			main.zoom_punch(2.0, 0.4)

func _update_shield_bubble():
	if shield_active and shield_bubble == null:
		shield_bubble = MeshInstance3D.new()
		var s = SphereMesh.new()
		s.radius = 1.3
		s.height = 2.6
		shield_bubble.mesh = s
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.6, 0.7, 0.9, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(0.4, 0.5, 0.8)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shield_bubble.material_override = mat
		add_child(shield_bubble)
		shield_bubble.position.y = 1.0
	elif not shield_active and shield_bubble != null:
		shield_bubble.queue_free()
		shield_bubble = null
	if shield_bubble:
		shield_bubble.rotation.y += get_physics_process_delta_time() * 2.0
