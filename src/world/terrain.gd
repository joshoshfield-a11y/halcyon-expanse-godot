extends Node
class_name TerrainBuilder

const SIZE: float = 240.0
const HALF: float = 120.0
const STEP: float = 1.5
const HEIGHT_AMP: float = 5.5

var noise: FastNoiseLite
var moisture: FastNoiseLite

const GROUND: Dictionary = {
	"temperate":  {"low": Color(0.18, 0.4, 0.14), "high": Color(0.3, 0.5, 0.2), "rock": Color(0.4, 0.38, 0.35), "dirt": Color(0.35, 0.3, 0.2)},
	"volcanic":   {"low": Color(0.12, 0.09, 0.09), "high": Color(0.25, 0.14, 0.1), "rock": Color(0.2, 0.16, 0.15), "dirt": Color(0.5, 0.16, 0.05)},
	"river":      {"low": Color(0.16, 0.38, 0.2), "high": Color(0.25, 0.5, 0.35), "rock": Color(0.38, 0.4, 0.42), "dirt": Color(0.3, 0.32, 0.22)},
	"void":       {"low": Color(0.07, 0.05, 0.12), "high": Color(0.14, 0.09, 0.22), "rock": Color(0.16, 0.12, 0.25), "dirt": Color(0.2, 0.08, 0.3)},
	"marsh":      {"low": Color(0.14, 0.26, 0.14), "high": Color(0.22, 0.34, 0.18), "rock": Color(0.3, 0.32, 0.28), "dirt": Color(0.24, 0.26, 0.16)},
	"industrial": {"low": Color(0.22, 0.2, 0.19), "high": Color(0.3, 0.28, 0.26), "rock": Color(0.35, 0.34, 0.36), "dirt": Color(0.32, 0.24, 0.16)},
	"crystal":    {"low": Color(0.14, 0.08, 0.24), "high": Color(0.22, 0.12, 0.36), "rock": Color(0.26, 0.16, 0.4), "dirt": Color(0.3, 0.14, 0.42)},
	"barren":     {"low": Color(0.32, 0.28, 0.22), "high": Color(0.42, 0.38, 0.3), "rock": Color(0.45, 0.42, 0.38), "dirt": Color(0.38, 0.3, 0.22)},
	"reef":       {"low": Color(0.14, 0.34, 0.34), "high": Color(0.2, 0.44, 0.4), "rock": Color(0.34, 0.4, 0.42), "dirt": Color(0.3, 0.34, 0.26)},
}

func _init(seed_val: int = 0):
	noise = FastNoiseLite.new()
	noise.seed = seed_val
	noise.frequency = 0.018
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.5
	moisture = FastNoiseLite.new()
	moisture.seed = seed_val * 7 + 13
	moisture.frequency = 0.05

func height_at(x: float, z: float) -> float:
	var h = noise.get_noise_2d(x, z) * HEIGHT_AMP
	var d = Vector2(x, z).length()
	var flat = clamp((d - 8.0) / 30.0, 0.0, 1.0)
	return h * flat

func _ground_color(biome: String, x: float, z: float, y: float, n: Vector3) -> Color:
	var pal = GROUND.get(biome, GROUND["temperate"])
	var mst = moisture.get_noise_2d(x, z) * 0.5 + 0.5
	var c = pal["low"].lerp(pal["high"], clamp(y / HEIGHT_AMP * 0.5 + 0.5, 0.0, 1.0))
	if mst > 0.62:
		c = c.lerp(pal["dirt"], (mst - 0.62) * 2.0)
	if n.y < 0.82:
		c = pal["rock"]
	return c

func build(parent: Node, biome: String) -> Dictionary:
	var root = Node3D.new()
	root.add_to_group("terrain")
	root.name = "Terrain"
	parent.add_child(root)

	var N = int(SIZE / STEP) + 1
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var uvs = PackedVector2Array()
	var heights = PackedFloat32Array()
	verts.resize(N * N)
	normals.resize(N * N)
	colors.resize(N * N)
	uvs.resize(N * N)
	heights.resize(N * N)

	for iz in range(N):
		for ix in range(N):
			var x = -HALF + ix * STEP
			var z = -HALF + iz * STEP
			var y = height_at(x, z)
			var idx = iz * N + ix
			verts[idx] = Vector3(x, y, z)
			heights[idx] = y
			var hx = height_at(x + 0.7, z) - height_at(x - 0.7, z)
			var hz = height_at(x, z + 0.7) - height_at(x, z - 0.7)
			var n = Vector3(-hx, 1.4, -hz).normalized()
			normals[idx] = n
			colors[idx] = _ground_color(biome, x, z, y, n)
			uvs[idx] = Vector2(x / 6.0, z / 6.0)

	var indices = PackedInt32Array()
	indices.resize((N - 1) * (N - 1) * 6)
	var k = 0
	for iz in range(N - 1):
		for ix in range(N - 1):
			var a = iz * N + ix
			var b2 = a + 1
			var c = a + N
			var d = a + N + 1
			indices[k] = a; indices[k+1] = b2; indices[k+2] = c
			indices[k+3] = b2; indices[k+4] = d; indices[k+5] = c
			k += 6

	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var gtex = load("res://assets/textures/ground_detail.png")
	if gtex:
		mat.albedo_texture = gtex
	mesh.surface_set_material(0, mat)

	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	root.add_child(mi)

	var body = StaticBody3D.new()
	body.collision_layer = 1
	var cs = CollisionShape3D.new()
	var hmap = HeightMapShape3D.new()
	hmap.map_width = N
	hmap.map_depth = N
	hmap.map_data = heights
	cs.shape = hmap
	cs.scale = Vector3(STEP, 1, STEP)
	body.add_child(cs)
	root.add_child(body)

	return {
		"spawn": Vector3(0, height_at(0, 0) + 1.3, 0),
		"gates": _place_gates(root),
		"items": _scatter_props(root, biome),
	}

func _place_gates(root: Node3D) -> Array:
	var gates = []
	var angles = [0.6, 2.7, 4.9]
	for a in angles:
		var dist = 65.0 + randf() * 25.0
		var x = sin(a) * dist
		var z = cos(a) * dist
		var y = height_at(x, z)
		var gate = Node3D.new()
		root.add_child(gate)
		gate.position = Vector3(x, y, z)
		for side in [-1, 1]:
			var pillar = MeshInstance3D.new()
			var pm = BoxMesh.new()
			pm.size = Vector3(0.7, 4.4, 0.7)
			pillar.mesh = pm
			var pmat = StandardMaterial3D.new()
			pmat.albedo_color = Color(0.25, 0.27, 0.32)
			pmat.metallic = 0.6
			pmat.roughness = 0.4
			pillar.material_override = pmat
			gate.add_child(pillar)
			pillar.position = Vector3(side * 1.6, 2.2, 0)
		var seam = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = Vector3(2.4, 3.6, 0.15)
		seam.mesh = sm
		var smat = StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smat.albedo_color = Color(0.1, 0.8, 1.0, 0.55)
		smat.emission_enabled = true
		smat.emission = Color(0.0, 0.7, 1.0)
		smat.emission_energy_multiplier = 2.5
		seam.material_override = smat
		gate.add_child(seam)
		seam.position = Vector3(0, 2.0, 0)
		gates.append(gate.global_position)
	return gates

func _scatter_props(root: Node3D, biome: String) -> Array:
	var items = []
	var rng = RandomNumberGenerator.new()
	rng.seed = noise.seed * 3 + 5
	for i in range(130):
		var x = rng.randf_range(-HALF + 8, HALF - 8)
		var z = rng.randf_range(-HALF + 8, HALF - 8)
		if Vector2(x, z).length() < 10.0:
			continue
		var y = height_at(x, z)
		var roll = rng.randf()
		if roll < 0.34:
			_make_tree(root, Vector3(x, y, z), biome, rng)
		elif roll < 0.62:
			_make_rock(root, Vector3(x, y, z), rng, roll < 0.45)
		elif roll < 0.8:
			_make_crystal_prop(root, Vector3(x, y, z), rng)
		else:
			_make_ruin(root, Vector3(x, y, z), rng)
	for i in range(12):
		var bx = rng.randf_range(-HALF + 12, HALF - 12)
		var bz = rng.randf_range(-HALF + 12, HALF - 12)
		if Vector2(bx, bz).length() < 9.0:
			continue
		_make_boulder(root, Vector3(bx, height_at(bx, bz) + 1.2, bz), rng)
	for i in range(14):
		var x = rng.randf_range(-HALF + 10, HALF - 10)
		var z = rng.randf_range(-HALF + 10, HALF - 10)
		if Vector2(x, z).length() < 8.0:
			continue
		items.append(Vector3(x, height_at(x, z), z))
	return items

func _make_tree(root: Node3D, pos: Vector3, biome: String, rng: RandomNumberGenerator):
	var t = Node3D.new()
	root.add_child(t)
	t.position = pos
	var trunk = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius = 0.14
	tm.bottom_radius = 0.24
	tm.height = 1.8
	trunk.mesh = tm
	var tmat = StandardMaterial3D.new()
	tmat.albedo_color = Color(0.3, 0.22, 0.14)
	tmat.roughness = 0.9
	var dtex = load("res://assets/textures/ground_detail.png")
	if dtex:
		tmat.albedo_texture = dtex
	trunk.material_override = tmat
	t.add_child(trunk)
	trunk.position.y = 0.9
	var canopy = MeshInstance3D.new()
	var cm = SphereMesh.new()
	cm.radius = 1.0 + rng.randf() * 0.5
	cm.height = cm.radius * 2.0
	canopy.mesh = cm
	var cmat = StandardMaterial3D.new()
	cmat.roughness = 0.85
	match biome:
		"volcanic": cmat.albedo_color = Color(0.25, 0.12, 0.1)
		"void":     cmat.albedo_color = Color(0.16, 0.1, 0.26)
		"crystal":  cmat.albedo_color = Color(0.3, 0.16, 0.45)
		"barren":   cmat.albedo_color = Color(0.4, 0.36, 0.24)
		"reef":     cmat.albedo_color = Color(0.15, 0.4, 0.38)
		"marsh":    cmat.albedo_color = Color(0.18, 0.3, 0.15)
		"industrial": cmat.albedo_color = Color(0.28, 0.26, 0.24)
		_:          cmat.albedo_color = Color(0.16, 0.4, 0.16)
	canopy.material_override = cmat
	canopy.scale = Vector3(1, 1.25, 1)
	t.add_child(canopy)
	canopy.position.y = 2.2
	t.rotation.y = rng.randf() * TAU
	var s = 0.8 + rng.randf() * 0.7
	t.scale = Vector3(s, s, s)

func _make_rock(root: Node3D, pos: Vector3, rng: RandomNumberGenerator, big: bool):
	var r = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.5 + rng.randf() * 0.6
	sm.height = sm.radius * 1.6
	r.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.34, 0.36).lerp(Color(0.2, 0.2, 0.22), rng.randf())
	mat.roughness = 0.95
	var dtex2 = load("res://assets/textures/ground_detail.png")
	if dtex2:
		mat.albedo_texture = dtex2
		mat.uv1_scale = Vector3(2, 2, 2)
	r.material_override = mat
	root.add_child(r)
	r.position = pos + Vector3(0, sm.radius * 0.4, 0)
	r.scale = Vector3(1.0 + rng.randf(), 0.6 + rng.randf() * 0.6, 1.0 + rng.randf())
	r.rotation.y = rng.randf() * TAU
	if big:
		var body = StaticBody3D.new()
		body.collision_layer = 1
		var cs = CollisionShape3D.new()
		var sph = SphereShape3D.new()
		sph.radius = sm.radius * 0.9
		cs.shape = sph
		body.add_child(cs)
		root.add_child(body)
		body.position = r.position

func _make_crystal_prop(root: Node3D, pos: Vector3, rng: RandomNumberGenerator):
	var c = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.4, 1.4 + rng.randf(), 0.4)
	c.mesh = bm
	var mat = StandardMaterial3D.new()
	var hue = rng.randf_range(0.5, 0.85)
	mat.albedo_color = Color.from_hsv(hue, 0.7, 0.9)
	mat.emission_enabled = true
	mat.emission = Color.from_hsv(hue, 0.8, 0.9)
	mat.emission_energy_multiplier = 1.5 + rng.randf()
	mat.roughness = 0.3
	c.material_override = mat
	root.add_child(c)
	c.position = pos + Vector3(0, bm.size.y * 0.35, 0)
	c.rotation.z = rng.randf_range(-0.3, 0.3)
	c.rotation.y = rng.randf() * TAU

func _make_ruin(root: Node3D, pos: Vector3, rng: RandomNumberGenerator):
	var n = rng.randi_range(2, 4)
	for i in range(n):
		var pillar = MeshInstance3D.new()
		var bm = BoxMesh.new()
		var h = 1.2 + rng.randf() * 2.8
		bm.size = Vector3(0.6, h, 0.6)
		pillar.mesh = bm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.4, 0.38).lerp(Color(0.25, 0.24, 0.26), rng.randf())
		mat.roughness = 0.9
		pillar.material_override = mat
		root.add_child(pillar)
		pillar.position = pos + Vector3(rng.randf_range(-2, 2), h * 0.5, rng.randf_range(-2, 2))
		pillar.rotation.z = rng.randf_range(-0.15, 0.15)
		pillar.rotation.y = rng.randf() * TAU

func _make_boulder(root: Node3D, pos: Vector3, rng: RandomNumberGenerator):
	var rb = RigidBody3D.new()
	rb.add_to_group("phys_props")
	rb.collision_layer = 16
	rb.collision_mask = 1 | 16
	rb.mass = 2.0
	var pm = PhysicsMaterial.new()
	pm.bounce = 0.25
	pm.friction = 0.8
	rb.physics_material_override = pm
	var rad = 0.35 + rng.randf() * 0.35
	var cs = CollisionShape3D.new()
	var sph = SphereShape3D.new()
	sph.radius = rad
	cs.shape = sph
	rb.add_child(cs)
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	mi.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.36, 0.3).lerp(Color(0.55, 0.3, 0.15), rng.randf())
	mat.roughness = 0.9
	var dtex = load("res://assets/textures/ground_detail.png")
	if dtex:
		mat.albedo_texture = dtex
	mi.material_override = mat
	rb.add_child(mi)
	root.add_child(rb)
	rb.global_position = pos
