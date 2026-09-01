extends GameEntity
class_name Enemy

@export var enemy_type: String = "Ash Wraith"
@export var behavior_pattern: String = "phase_cycle"
@export var detection_range: float = 9.0
@export var attack_range: float = 1.6
@export var move_speed: float = 2.5
@export var damage: int = 12
@export var xp_value: int = 25
@export var loot_table: Array = []

var state_machine: String = "idle"
var state_timer: float = 0.0
var patrol_target: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0
var phase: int = 0
var is_elite: bool = false
var knockback_vel: Vector3 = Vector3.ZERO
var vy: float = 0.0
var slow_factor: float = 1.0
var slow_timer: float = 0.0
var dying: bool = false
var xp_awarded: bool = false
var mesh_inst: MeshInstance3D = null
var bob_t: float = 0.0

const GRAVITY: float = 22.0
const TYPE_COLORS: Dictionary = {
	"Ash Wraith":    {"body": Color(0.55, 0.25, 0.7), "glow": Color(0.6, 0.2, 0.9), "shape": "capsule"},
	"Hollow Stalker":{"body": Color(0.15, 0.15, 0.25), "glow": Color(0.3, 0.3, 0.6), "shape": "capsule_tall"},
	"Iron Drone":    {"body": Color(0.45, 0.45, 0.5), "glow": Color(1.0, 0.6, 0.1), "shape": "box"},
	"Tide Serpent":  {"body": Color(0.1, 0.4, 0.55), "glow": Color(0.1, 0.7, 0.9), "shape": "long"},
	"Chorus Knight": {"body": Color(0.6, 0.55, 0.2), "glow": Color(1.0, 0.9, 0.3), "shape": "knight"},
	"Swarm Mite":    {"body": Color(0.5, 0.3, 0.15), "glow": Color(0.9, 0.5, 0.1), "shape": "small"},
}

func _init():
	hp = 80
	max_hp = 80

func _ready():
	add_to_group("enemies")
	floor_snap_length = 0.4
	var hb = get_node_or_null("HPBar")
	if hb:
		hb.visible = false
	mesh_inst = get_node_or_null("MeshInstance3D")
	bob_t = randf() * TAU
	_apply_visuals()

func make_elite():
	is_elite = true
	max_hp = int(max_hp * 3)
	hp = max_hp
	damage = int(damage * 1.8)
	xp_value = xp_value * 3
	scale = Vector3(1.45, 1.45, 1.45)
	move_speed *= 1.1

func _apply_visuals():
	if mesh_inst == null:
		return
	var spec = TYPE_COLORS.get(enemy_type, {"body": Color(0.7, 0.2, 0.2), "glow": Color(1, 0.3, 0.3), "shape": "capsule"})
	var mesh: Mesh
	match spec["shape"]:
		"box":
			var b = BoxMesh.new()
			b.size = Vector3(0.9, 0.9, 0.9)
			mesh = b
		"long":
			var c = CapsuleMesh.new()
			c.radius = 0.35
			c.height = 2.4
			mesh = c
		"knight":
			var cy = CylinderMesh.new()
			cy.top_radius = 0.35
			cy.bottom_radius = 0.6
			cy.height = 2.0
			mesh = cy
		"small":
			var s = SphereMesh.new()
			s.radius = 0.4
			s.height = 0.8
			mesh = s
		"capsule_tall":
			var ct = CapsuleMesh.new()
			ct.radius = 0.4
			ct.height = 2.6
			mesh = ct
		_:
			var cp = CapsuleMesh.new()
			cp.radius = 0.5
			cp.height = 2.0
			mesh = cp
	mesh_inst.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = spec["body"]
	mat.emission_enabled = true
	mat.emission = spec["glow"]
	mat.emission_energy_multiplier = 0.7
	mat.metallic = 0.25
	mat.roughness = 0.6
	if is_elite:
		mat.emission = Color(0.8, 0.3, 1.0)
		mat.emission_energy_multiplier = 1.6
	mesh_inst.material_override = mat
	mesh_inst.position.y = 1.0
	_add_eyes(spec["glow"])

func _add_eyes(glow: Color):
	for side in [-1, 1]:
		var eye = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18
		eye.mesh = sm
		var em = StandardMaterial3D.new()
		em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		em.albedo_color = Color(1, 1, 1)
		em.emission_enabled = true
		em.emission = glow.lerp(Color(1, 1, 1), 0.4)
		em.emission_energy_multiplier = 3.0 if is_elite else 2.0
		eye.material_override = em
		mesh_inst.add_child(eye)
		eye.position = Vector3(side * 0.22, 0.55, 0.42)

func apply_slow(factor: float, duration: float):
	slow_factor = factor
	slow_timer = duration

func apply_knockback(dir: Vector3, force: float = 6.0, launch: float = 0.0):
	knockback_vel += dir.normalized() * force
	if launch > 0.0:
		vy = max(vy, launch)

func take_damage(amount: int) -> int:
	if dying:
		return hp
	var dealt = max(amount, 1)
	var result = super.take_damage(dealt)
	if mesh_inst:
		Juice.flash(mesh_inst, 3.5, 0.1)
	if hp <= 0:
		die()
	return result

func die():
	if dying:
		return
	dying = true
	dead = true
	collision_layer = 0
	collision_mask = 0
	var main = get_node_or_null("/root/Main")
	var body_col = Color(1, 0.4, 0.3)
	if enemy_type in TYPE_COLORS:
		body_col = TYPE_COLORS[enemy_type]["glow"]
	if main:
		Juice.burst(main, global_position + Vector3(0, 1, 0), body_col, 28 if is_elite else 16, 6.0, 0.6, 0.1)
		if is_elite:
			Juice.ring(main, global_position, Color(0.8, 0.3, 1.0), 4.0, 0.5)
		Pickup.spawn(main, global_position, "lc", 60 + xp_value)
		if randf() < 0.3 or is_elite:
			Pickup.spawn(main, global_position + Vector3(0.8, 0, 0.4), "hp", 25)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "position:y", position.y - 0.5, 0.35)
	tw.tween_callback(queue_free)

func update(dt: float, player_pos: Vector3):
	if dead:
		return
	state_timer -= dt
	attack_cooldown -= dt
	if slow_timer > 0:
		slow_timer -= dt
		if slow_timer <= 0:
			slow_factor = 1.0
	var dist = global_position.distance_to(player_pos)
	var spd = move_speed * slow_factor

	# behaviors return planar velocity; physics applied once below
	var planar: Vector3
	match behavior_pattern:
		"patrol_loop":
			planar = _behavior_patrol(dt, dist, player_pos, spd)
		"stealth_ambush":
			planar = _behavior_ambush(dt, dist, player_pos, spd)
		"area_pulse":
			planar = _behavior_pulse(dt, dist, player_pos, spd)
		"buff_ally":
			planar = _behavior_buff(dt, dist, player_pos, spd)
		"swarm_split":
			planar = _behavior_swarm(dt, dist, player_pos, spd)
		_:
			planar = _behavior_chase(dt, dist, player_pos, spd)

	# unified physics: planar + knockback + gravity
	planar += knockback_vel
	knockback_vel = knockback_vel.lerp(Vector3.ZERO, min(10.0 * dt, 1.0))
	if is_on_floor():
		vy = -0.5
	else:
		vy -= GRAVITY * dt
	velocity = Vector3(planar.x, vy, planar.z)
	move_and_slide()

	# face travel direction + idle bob
	if mesh_inst:
		if planar.length() > 0.2:
			mesh_inst.rotation.y = lerp_angle(mesh_inst.rotation.y, atan2(planar.x, planar.z), 8.0 * dt)
		bob_t += dt * 2.2
		mesh_inst.position.y = 1.0 + sin(bob_t) * 0.05

func _chase_vel(player_pos: Vector3, spd: float) -> Vector3:
	var dir = player_pos - global_position
	dir.y = 0
	return dir.normalized() * spd if dir.length() > 0.01 else Vector3.ZERO

func _behavior_chase(dt: float, dist: float, player_pos: Vector3, spd: float) -> Vector3:
	if dist < detection_range:
		if dist > attack_range:
			return _chase_vel(player_pos, spd)
		if attack_cooldown <= 0:
			attack_cooldown = 1.5
			state_machine = "attack"
	return Vector3.ZERO

func _behavior_patrol(dt: float, dist: float, player_pos: Vector3, spd: float) -> Vector3:
	if dist < detection_range:
		return _chase_vel(player_pos, spd)
	if state_timer <= 0:
		patrol_target = global_position + Vector3(randi() % 10 - 5, 0, randi() % 10 - 5)
		state_timer = 3.0
	var dir = patrol_target - global_position
	dir.y = 0
	if dir.length() > 0.5:
		return dir.normalized() * spd * 0.5
	return Vector3.ZERO

func _behavior_ambush(dt: float, dist: float, player_pos: Vector3, spd: float) -> Vector3:
	if dist < detection_range * 0.5:
		return _chase_vel(player_pos, spd * 2.0)
	return Vector3.ZERO

func _behavior_pulse(dt: float, dist: float, player_pos: Vector3, spd: float) -> Vector3:
	if state_timer <= 0:
		state_timer = 4.0
		state_machine = "pulse"
	if dist < detection_range:
		return _chase_vel(player_pos, spd * 0.35)
	return Vector3.ZERO

func _behavior_buff(dt: float, dist: float, player_pos: Vector3, spd: float) -> Vector3:
	if state_timer <= 0:
		state_timer = 6.0
		state_machine = "buff"
	if dist < detection_range:
		return _chase_vel(player_pos, spd * 0.7)
	return Vector3.ZERO

func _behavior_swarm(dt: float, dist: float, player_pos: Vector3, spd: float) -> Vector3:
	if dist < detection_range:
		return _chase_vel(player_pos, spd * 1.25)
	return Vector3.ZERO
