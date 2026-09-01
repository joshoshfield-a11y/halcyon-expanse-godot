extends RefCounted
class_name Juice

# One-shot particle burst. Parent should be a Node3D (Main or Entities).
static func burst(parent: Node, pos: Vector3, color: Color, count: int = 24, speed: float = 5.0, life: float = 0.55, size: float = 0.09):
	var p = GPUParticles3D.new()
	p.amount = count
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -12, 0)
	pm.scale_min = size * 0.6
	pm.scale_max = size
	pm.color = color
	p.process_material = pm
	var mesh = BoxMesh.new()
	mesh.size = Vector3(size, size, size)
	p.draw_pass_1 = mesh
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

# Expanding shockwave ring on the ground.
static func ring(parent: Node, pos: Vector3, color: Color, max_radius: float = 5.0, dur: float = 0.45):
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.08
	cyl.radial_segments = 48
	cyl.rings = 1
	mi.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.55
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.15, 0)
	mi.scale = Vector3(0.3, 1, 0.3)
	var tw = mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(max_radius, 1, max_radius), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, dur)
	tw.tween_callback(mi.queue_free)

# Floating combat text.
static func damage_text(parent: Node, pos: Vector3, text: String, color: Color = Color(1, 0.9, 0.3), big: bool = false):
	var l = Label3D.new()
	l.text = text
	l.font_size = 96 if big else 64
	l.pixel_size = 0.008
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = color
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.8)
	parent.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.4, 0.4), 2.2, randf_range(-0.4, 0.4))
	var tw = l.create_tween()
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, 1.6, 0), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.15)
	tw.tween_callback(l.queue_free)

# Brief emissive flash on a MeshInstance3D with its own material.
static func flash(mesh_inst: MeshInstance3D, strength: float = 4.0, dur: float = 0.09):
	if mesh_inst == null or not (mesh_inst.material_override is StandardMaterial3D):
		return
	var mat: StandardMaterial3D = mesh_inst.material_override
	var old_energy = mat.emission_energy_multiplier
	var old_emission = mat.emission
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = strength
	var tw = mesh_inst.create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func():
		if is_instance_valid(mat):
			mat.emission = old_emission
			mat.emission_energy_multiplier = old_energy)
