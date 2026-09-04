extends RefCounted
class_name CharRig

# Builds an articulated humanoid (torso, head, 2 arms, 2 legs) entirely in code.
# Returns a dict of pivots; animate() drives a procedural run/idle cycle.

static func _mat(col: Color, emission: Color = Color(0, 0, 0), e: float = 0.0, metal: float = 0.2, rough: float = 0.55) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	if e > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = e
	m.metallic = metal
	m.roughness = rough
	return m

static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	parent.add_child(mi)
	mi.position = pos
	return mi

static func build(parent: Node3D, body: Color, glow: Color, accent: Color = Color(0.2, 0.2, 0.25)) -> Dictionary:
	var root = Node3D.new()
	root.name = "Rig"
	parent.add_child(root)

	var suit = _mat(body, glow, 0.5, 0.35, 0.45)
	var dark = _mat(accent, Color(0, 0, 0), 0.0, 0.5, 0.5)
	var glow_m = _mat(glow.lightened(0.3), glow, 2.2, 0.0, 0.3)

	# torso + pelvis
	var torso = _box(root, Vector3(0.62, 0.62, 0.36), Vector3(0, 1.42, 0), suit)
	_box(root, Vector3(0.5, 0.28, 0.32), Vector3(0, 1.02, 0), dark)
	# chest light strip
	_box(torso, Vector3(0.5, 0.08, 0.05), Vector3(0, 0.12, 0.19), glow_m)

	# head
	var head = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.26
	hm.height = 0.52
	head.mesh = hm
	head.material_override = dark
	root.add_child(head)
	head.position = Vector3(0, 1.92, 0)
	# visor
	_box(head, Vector3(0.34, 0.12, 0.12), Vector3(0, 0.02, 0.2), glow_m)

	# arms: pivot at shoulder
	var arm_l = Node3D.new()
	root.add_child(arm_l)
	arm_l.position = Vector3(-0.42, 1.68, 0)
	_box(arm_l, Vector3(0.18, 0.72, 0.2), Vector3(0, -0.36, 0), suit)
	_box(arm_l, Vector3(0.2, 0.16, 0.22), Vector3(0, -0.7, 0), glow_m)
	var arm_r = Node3D.new()
	root.add_child(arm_r)
	arm_r.position = Vector3(0.42, 1.68, 0)
	_box(arm_r, Vector3(0.18, 0.72, 0.2), Vector3(0, -0.36, 0), suit)
	_box(arm_r, Vector3(0.2, 0.16, 0.22), Vector3(0, -0.7, 0), glow_m)

	# legs: pivot at hip
	var leg_l = Node3D.new()
	root.add_child(leg_l)
	leg_l.position = Vector3(-0.17, 0.92, 0)
	_box(leg_l, Vector3(0.22, 0.86, 0.24), Vector3(0, -0.43, 0), dark)
	_box(leg_l, Vector3(0.24, 0.12, 0.34), Vector3(0, -0.86, 0.05), suit)
	var leg_r = Node3D.new()
	root.add_child(leg_r)
	leg_r.position = Vector3(0.17, 0.92, 0)
	_box(leg_r, Vector3(0.22, 0.86, 0.24), Vector3(0, -0.43, 0), dark)
	_box(leg_r, Vector3(0.24, 0.12, 0.34), Vector3(0, -0.86, 0.05), suit)

	# shoulder pads
	_box(root, Vector3(0.26, 0.14, 0.28), Vector3(-0.44, 1.76, 0), dark)
	_box(root, Vector3(0.26, 0.14, 0.28), Vector3(0.44, 1.76, 0), dark)
	# backpack
	_box(root, Vector3(0.4, 0.44, 0.2), Vector3(0, 1.45, -0.28), dark)
	_box(root, Vector3(0.3, 0.06, 0.06), Vector3(0, 1.58, -0.39), glow_m)

	# cape: pivot at upper back, flows with movement in animate()
	var cape = Node3D.new()
	root.add_child(cape)
	cape.position = Vector3(0, 1.7, -0.22)
	var cape_mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(0.55, 0.95)
	pm.subdivide_width = 3
	pm.subdivide_depth = 3
	cape_mi.mesh = pm
	var cape_mat = StandardMaterial3D.new()
	cape_mat.albedo_color = glow.darkened(0.25)
	cape_mat.emission_enabled = true
	cape_mat.emission = glow
	cape_mat.emission_energy_multiplier = 0.35
	cape_mat.roughness = 0.8
	cape_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cape_mi.material_override = cape_mat
	cape.add_child(cape_mi)
	cape_mi.position = Vector3(0, -0.48, 0)
	cape_mi.rotation.x = PI / 2 * 0.12

	return {"root": root, "torso": torso, "head": head, "cape": cape,
			"arm_l": arm_l, "arm_r": arm_r, "leg_l": leg_l, "leg_r": leg_r,
			"flash_mats": [suit, dark], "base_glow": glow}

# Procedural locomotion. speed_ratio 0..1, phase advances with distance travelled.
static func animate(rig: Dictionary, phase: float, speed_ratio: float, airborne: bool, dt: float, lean: float = 0.0):
	var sw = sin(phase)
	var cw = cos(phase)
	# sideways lean when turning + cape flow (shared across poses)
	rig["root"].rotation.z = lerp(rig["root"].rotation.z, clamp(lean, -0.22, 0.22), 8.0 * dt)
	if rig.has("cape"):
		var cape_target = 0.12 + speed_ratio * 1.05 + (0.9 if airborne else 0.0)
		rig["cape"].rotation.x = lerp(rig["cape"].rotation.x, cape_target, 5.0 * dt)
		rig["cape"].rotation.z = sin(Time.get_ticks_msec() / 1000.0 * 3.1) * 0.08 * (0.3 + speed_ratio)
	if airborne:
		# tucked jump pose
		rig["leg_l"].rotation.x = lerp(rig["leg_l"].rotation.x, -0.7, 10.0 * dt)
		rig["leg_r"].rotation.x = lerp(rig["leg_r"].rotation.x, 0.4, 10.0 * dt)
		rig["arm_l"].rotation.x = lerp(rig["arm_l"].rotation.x, -2.4, 8.0 * dt)
		rig["arm_r"].rotation.x = lerp(rig["arm_r"].rotation.x, -2.4, 8.0 * dt)
		rig["root"].rotation.x = lerp(rig["root"].rotation.x, 0.08, 6.0 * dt)
	elif speed_ratio > 0.05:
		var k = speed_ratio
		rig["leg_l"].rotation.x = sw * 0.75 * k
		rig["leg_r"].rotation.x = -sw * 0.75 * k
		rig["arm_l"].rotation.x = -sw * 0.6 * k
		rig["arm_r"].rotation.x = sw * 0.6 * k
		# forward lean + bob while running
		rig["root"].rotation.x = lerp(rig["root"].rotation.x, 0.14 * k, 8.0 * dt)
		rig["root"].position.y = abs(cw) * 0.08 * k
	else:
		# idle sway / breathe
		var t = Time.get_ticks_msec() / 1000.0
		rig["leg_l"].rotation.x = lerp(rig["leg_l"].rotation.x, 0.0, 10.0 * dt)
		rig["leg_r"].rotation.x = lerp(rig["leg_r"].rotation.x, 0.0, 10.0 * dt)
		rig["arm_l"].rotation.x = lerp(rig["arm_l"].rotation.x, sin(t * 1.6) * 0.05, 6.0 * dt)
		rig["arm_r"].rotation.x = lerp(rig["arm_r"].rotation.x, -sin(t * 1.6) * 0.05, 6.0 * dt)
		rig["root"].rotation.x = lerp(rig["root"].rotation.x, 0.0, 8.0 * dt)
		rig["root"].position.y = lerp(rig["root"].position.y, 0.0, 10.0 * dt)
		rig["torso"].scale = Vector3(1.0, 1.0 + sin(t * 2.0) * 0.02, 1.0)

# Melee swing: right arm arcs overhead and chops down.
static func attack_swing(rig: Dictionary):
	var arm: Node3D = rig["arm_r"]
	var tw = arm.create_tween()
	tw.tween_property(arm, "rotation:x", -2.6, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(arm, "rotation:x", 0.9, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(arm, "rotation:x", 0.0, 0.2).set_trans(Tween.TRANS_SPRING)

# Flash all body materials (damage feedback).
static func flash(rig: Dictionary, strength: float = 3.5, dur: float = 0.12):
	for m in rig["flash_mats"]:
		m.emission_enabled = true
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = strength
	await Engine.get_main_loop().create_timer(dur).timeout
	for m in rig["flash_mats"]:
		m.emission = rig["base_glow"] if m == rig["flash_mats"][0] else Color(0, 0, 0)
		m.emission_energy_multiplier = 0.5 if m == rig["flash_mats"][0] else 0.0

# Landing squash-and-stretch.
static func squash(rig: Dictionary, amount: float = 0.7):
	var root: Node3D = rig["root"]
	var tw = root.create_tween()
	tw.tween_property(root, "scale", Vector3(1.15, amount, 1.15), 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "scale", Vector3(1, 1, 1), 0.28).set_trans(Tween.TRANS_SPRING)

# Rigidbody debris chunks that bounce on the terrain, then shrink away.
static func spawn_debris(parent: Node, pos: Vector3, color: Color, count: int = 5, power: float = 5.0):
	for i in range(count):
		var rb = RigidBody3D.new()
		rb.collision_layer = 0
		rb.collision_mask = 1
		rb.mass = 0.4
		rb.gravity_scale = 1.6
		var cs = CollisionShape3D.new()
		var bs = BoxShape3D.new()
		var sz = randf_range(0.12, 0.3)
		bs.size = Vector3(sz, sz, sz)
		cs.shape = bs
		rb.add_child(cs)
		var mi = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(sz, sz, sz)
		mi.mesh = bm
		var m = StandardMaterial3D.new()
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.8
		mi.material_override = m
		rb.add_child(mi)
		parent.add_child(rb)
		rb.global_position = pos + Vector3(randf_range(-0.3, 0.3), randf_range(0.5, 1.2), randf_range(-0.3, 0.3))
		rb.apply_central_impulse(Vector3(randf_range(-1, 1), randf_range(0.6, 1.4), randf_range(-1, 1)).normalized() * power * randf_range(0.5, 1.2))
		rb.apply_torque_impulse(Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4)))
		rb.angular_damp = 0.5
		_shrink_later(rb)

static func _shrink_later(rb: RigidBody3D):
	await Engine.get_main_loop().create_timer(0.9).timeout
	if not is_instance_valid(rb):
		return
	var tw = rb.create_tween()
	tw.tween_property(rb, "scale", Vector3.ZERO, 0.4)
	tw.tween_callback(rb.queue_free)
