extends StaticBody3D

var tile_type: int = 0
var biome: String = "temperate"

func setup(t: int, b: String):
	tile_type = t
	biome = b
	_update_mesh()

func _update_mesh():
	var mesh = BoxMesh.new()
	var mat = StandardMaterial3D.new()

	match tile_type:
		ExpanseTileData.TileType.FLOOR_GRASS:
			mesh.size = Vector3(2, 0.2, 2)
			mat.albedo_color = Color(0.2, 0.5, 0.15)
			$MeshInstance3D.position.y = -0.1
		ExpanseTileData.TileType.FLOOR_STONE:
			mesh.size = Vector3(2, 0.2, 2)
			mat.albedo_color = Color(0.4, 0.4, 0.42)
			$MeshInstance3D.position.y = -0.1
		ExpanseTileData.TileType.FLOOR_ASH:
			mesh.size = Vector3(2, 0.2, 2)
			mat.albedo_color = Color(0.25, 0.2, 0.18)
			$MeshInstance3D.position.y = -0.1
		ExpanseTileData.TileType.FLOOR_CRYSTAL:
			mesh.size = Vector3(2, 0.2, 2)
			mat.albedo_color = Color(0.6, 0.3, 0.8)
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.1, 0.5)
			$MeshInstance3D.position.y = -0.1
		ExpanseTileData.TileType.FLOOR_IRON:
			mesh.size = Vector3(2, 0.2, 2)
			mat.albedo_color = Color(0.35, 0.35, 0.4)
			mat.metallic = 0.8
			$MeshInstance3D.position.y = -0.1
		ExpanseTileData.TileType.FLOOR_WATER:
			mesh.size = Vector3(2, 0.5, 2)
			mat.albedo_color = Color(0.1, 0.3, 0.6)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.7
			$MeshInstance3D.position.y = -0.25
		ExpanseTileData.TileType.FLOOR_LAVA:
			mesh.size = Vector3(2, 0.3, 2)
			mat.albedo_color = Color(0.9, 0.2, 0.05)
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.1, 0.0)
			$MeshInstance3D.position.y = -0.15
		ExpanseTileData.TileType.WALL_STONE, ExpanseTileData.TileType.WALL_METAL, ExpanseTileData.TileType.WALL_CRYSTAL:
			mesh.size = Vector3(2, 3, 2)
			if tile_type == ExpanseTileData.TileType.WALL_STONE:
				mat.albedo_color = Color(0.35, 0.35, 0.38)
			elif tile_type == ExpanseTileData.TileType.WALL_METAL:
				mat.albedo_color = Color(0.4, 0.4, 0.45)
				mat.metallic = 0.9
			else:
				mat.albedo_color = Color(0.5, 0.2, 0.7)
				mat.emission_enabled = true
				mat.emission = Color(0.3, 0.1, 0.5)
			$MeshInstance3D.position.y = 1.5
		ExpanseTileData.TileType.GATE_SEAM:
			mesh.size = Vector3(2, 3, 2)
			mat.albedo_color = Color(0.1, 0.8, 0.9)
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.5, 0.8)
			$MeshInstance3D.position.y = 1.5
		_:
			mesh.size = Vector3(2, 0.2, 2)
			mat.albedo_color = Color(0.3, 0.3, 0.3)
			$MeshInstance3D.position.y = -0.1

	$MeshInstance3D.mesh = mesh
	$MeshInstance3D.material_override = mat

	# Update collision
	var shape = BoxShape3D.new()
	shape.size = mesh.size
	$CollisionShape3D.shape = shape
	$CollisionShape3D.position = $MeshInstance3D.position
