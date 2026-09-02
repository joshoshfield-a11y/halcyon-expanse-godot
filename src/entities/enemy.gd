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
var rig: Dictionary = {}
var walk_phase: float = 0.0

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
	collision_mask = 7 | 16
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
	# hide the placeholder capsule, build an articulated rig tinted per type
	mesh_inst.visible = false
	var accent = spec["body"].darkened(0.45)
	rig = CharRig.build(self, spec["body"], spec["glow"], accent)
	match spec["shape"]:
		"small":
			rig["root"].scale = Vector3(0.62, 0.62, 0.62)
		"capsule_tall", "long":
			rig["root"].scale = Vector3(0.9, 1.18, 0.9)
		"knight":
			rig["root"].scale = Vector3(1.18, 1.08, 1.18)
		"box":
			rig["root"].scale = Vector3(1.1, 0.95, 1.1)
	if is_elite:
		for m in rig["flash_mats"]:
			m.emission_enabled = true
			m.emission = Color(0.8, 0.3, 1.0)
			m.emission_energy_multiplier = 1.4
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
		if rig:
			rig["head"].add_child(eye)
			eye.position = Vector3(side * 0.12, 0.03, 0.22)
		else:
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
	if rig:
		CharRig.flash(rig, 3.5, 0.1)
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
		CharRig.spawn_debris(main, global_position, body_col, 7 if is_elite else 4, 5.5 if is_elite else 4.0)
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

	# face travel direction + procedural walk cycle
	if rig:
		var travel = Vector3(velocity.x, 0, velocity.z)
		if travel.length() > 0.3:
			rig["root"].rotation.y = lerp_angle(rig["root"].rotation.y, atan2(travel.x, travel.z), 8.0 * dt)
		walk_phase += travel.length() * dt * 1.9
		var spd_ratio = clamp(travel.length() / max(move_speed, 0.1), 0.0, 1.0)
		CharRig.animate(rig, walk_phase, spd_ratio, not is_on_floor(), dt)

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
