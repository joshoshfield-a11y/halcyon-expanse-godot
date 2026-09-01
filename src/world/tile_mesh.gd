extends StaticBody3D

var tile_type: int = 0
var biome: String = "temperate"

# subtle deterministic jitter so the floor doesn't look like a grid of clones
func _jitter() -> float:
	var s = sin(global_position.x * 12.9898 + global_position.z * 78.233) * 43758.5453
	return s - floor(s)

func setup(t: int, b: String):
	tile_type = t
	biome = b
	_update_mesh()

func _update_mesh():
	var mesh = BoxMesh.new()
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.85
	var j = _jitter()

	match tile_type:
		ExpanseTileData.TileType.FLOOR_GRASS:
			mesh.size = Vector3(2, 0.2 + j * 0.12, 2)
			mat.albedo_color = Color(0.16 + j * 0.1, 0.42 + j * 0.12, 0.14)
		ExpanseTileData.TileType.FLOOR_STONE:
			mesh.size = Vector3(2, 0.2 + j * 0.1, 2)
			mat.albedo_color = Color(0.34 + j * 0.1, 0.34 + j * 0.1, 0.37 + j * 0.08)
		ExpanseTileData.TileType.FLOOR_ASH:
			mesh.size = Vector3(2, 0.2 + j * 0.1, 2)
			mat.albedo_color = Color(0.22 + j * 0.06, 0.18 + j * 0.05, 0.16)
		ExpanseTileData.TileType.FLOOR_CRYSTAL:
			mesh.size = Vector3(2, 0.25 + j * 0.15, 2)
			mat.albedo_color = Color(0.5, 0.25, 0.7)
			mat.emission_enabled = true
			mat.emission = Color(0.35, 0.12, 0.55)
			mat.emission_energy_multiplier = 0.6 + j * 0.8
		ExpanseTileData.TileType.FLOOR_IRON:
			mesh.size = Vector3(2, 0.2 + j * 0.08, 2)
			mat.albedo_color = Color(0.33, 0.34, 0.4)
			mat.metallic = 0.85
			mat.roughness = 0.35
		ExpanseTileData.TileType.FLOOR_WATER:
			mesh.size = Vector3(2, 0.5, 2)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(0.1, 0.35, 0.65, 0.7)
			mat.emission_enabled = true
			mat.emission = Color(0.05, 0.2, 0.4)
			mat.emission_energy_multiplier = 0.5
		ExpanseTileData.TileType.FLOOR_LAVA:
			mesh.size = Vector3(2, 0.3, 2)
			mat.albedo_color = Color(0.9, 0.2, 0.05)
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.15, 0.0)
			mat.emission_energy_multiplier = 1.2 + j * 1.2
		ExpanseTileData.TileType.WALL_STONE, ExpanseTileData.TileType.WALL_METAL, ExpanseTileData.TileType.WALL_CRYSTAL:
			mesh.size = Vector3(2, 3, 2)
			if tile_type == ExpanseTileData.TileType.WALL_STONE:
				mat.albedo_color = Color(0.3 + j * 0.08, 0.3 + j * 0.08, 0.34)
			elif tile_type == ExpanseTileData.TileType.WALL_METAL:
				mat.albedo_color = Color(0.38, 0.39, 0.45)
				mat.metallic = 0.9
				mat.roughness = 0.3
			else:
				mat.albedo_color = Color(0.45, 0.18, 0.65)
				mat.emission_enabled = true
				mat.emission = Color(0.35, 0.1, 0.55)
				mat.emission_energy_multiplier = 1.0
		ExpanseTileData.TileType.GATE_SEAM:
			mesh.size = Vector3(2, 3.4, 2)
			mat.albedo_color = Color(0.08, 0.7, 0.85)
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.6, 0.9)
			mat.emission_energy_multiplier = 2.0
		_:
			mesh.size = Vector3(2, 0.2, 2)
			mat.albedo_color = Color(0.25, 0.25, 0.28)

	$MeshInstance3D.mesh = mesh
	$MeshInstance3D.material_override = mat
	if tile_type in [ExpanseTileData.TileType.WALL_STONE, ExpanseTileData.TileType.WALL_METAL, ExpanseTileData.TileType.WALL_CRYSTAL]:
		_add_wall_trim()
	if mesh.size.y > 1.0:
		$MeshInstance3D.position.y = mesh.size.y / 2.0
	elif tile_type == ExpanseTileData.TileType.FLOOR_WATER:
		$MeshInstance3D.position.y = -0.25
	else:
		$MeshInstance3D.position.y = -0.1 + mesh.size.y * 0.25

	# occasional lattice crystal decoration on plain floors
	if tile_type in [ExpanseTileData.TileType.FLOOR_GRASS, ExpanseTileData.TileType.FLOOR_STONE, ExpanseTileData.TileType.FLOOR_ASH, ExpanseTileData.TileType.FLOOR_IRON] and j > 0.93:
		var deco = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.3, 0.7, 0.3)
		deco.mesh = bm
		var dm = StandardMaterial3D.new()
		dm.albedo_color = Color(0.3, 0.9, 1.0)
		dm.emission_enabled = true
		dm.emission = Color(0.2, 0.7, 1.0)
		dm.emission_energy_multiplier = 2.5
		deco.material_override = dm
		deco.position = Vector3(j * 1.2 - 0.6, 0.45, (1.0 - j) * 1.2 - 0.6)
		deco.rotation.y = j * TAU
		deco.rotation.z = 0.3
		add_child(deco)

	var shape = BoxShape3D.new()
	shape.size = mesh.size
	$CollisionShape3D.shape = shape
	$CollisionShape3D.position = $MeshInstance3D.position


func _add_wall_trim():
	var trim = MeshInstance3D.new()
	var tb = BoxMesh.new()
	tb.size = Vector3(2.04, 0.09, 2.04)
	trim.mesh = tb
	var tm2 = StandardMaterial3D.new()
	tm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var col = Color(0.9, 0.6, 0.25)
	if tile_type == ExpanseTileData.TileType.WALL_METAL:
		col = Color(1.0, 0.55, 0.1)
	elif tile_type == ExpanseTileData.TileType.WALL_CRYSTAL:
		col = Color(0.7, 0.3, 1.0)
	tm2.albedo_color = col
	tm2.emission_enabled = true
	tm2.emission = col
	tm2.emission_energy_multiplier = 1.6
	trim.material_override = tm2
	add_child(trim)
	trim.position.y = 3.06
