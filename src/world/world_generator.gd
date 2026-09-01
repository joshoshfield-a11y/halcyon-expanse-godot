extends Node
class_name WorldGenerator

var rng: RandomNumberGenerator
var map_width: int = 40
var map_height: int = 40
var tile_size: float = 2.0

func _init(seed_val: int = 0):
	rng = RandomNumberGenerator.new()
	rng.seed = seed_val

func generate_system(system_name: String, biome: String) -> Dictionary:
	var tiles = []
	var spawn_points = []
	var gates = []
	var enemies = []
	var items = []
	var tileset = ExpanseTileData.get_biome_tiles(biome)

	for y in range(map_height):
		var row = []
		for x in range(map_width):
			var tile = tileset[rng.randi() % tileset.size()]
			# Border walls
			if x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1:
				tile = ExpanseTileData.TileType.WALL_STONE
			# Random structures
			elif rng.randf() < 0.08:
				tile = ExpanseTileData.TileType.WALL_STONE
			# Seam gates
			elif rng.randf() < 0.02 and x > 5 and x < map_width - 5 and y > 5 and y < map_height - 5:
				tile = ExpanseTileData.TileType.GATE_SEAM
				gates.append(Vector2i(x, y))
			# Enemy spawns
			elif rng.randf() < 0.03 and ExpanseTileData.is_walkable(tile):
				enemies.append(Vector2i(x, y))
			# Item spawns
			elif rng.randf() < 0.02 and ExpanseTileData.is_walkable(tile):
				items.append(Vector2i(x, y))
			row.append(tile)
		tiles.append(row)

	# Player spawn center
	spawn_points.append(Vector2i(map_width / 2, map_height / 2))
	tiles[map_height / 2][map_width / 2] = ExpanseTileData.TileType.FLOOR_STONE

	return {
		"name": system_name,
		"biome": biome,
		"tiles": tiles,
		"spawn_points": spawn_points,
		"gates": gates,
		"enemy_spawns": enemies,
		"item_spawns": items,
		"width": map_width,
		"height": map_height
	}

func world_to_grid(pos: Vector3) -> Vector2i:
	return Vector2i(int(pos.x / tile_size), int(pos.z / tile_size))

func grid_to_world(grid: Vector2i) -> Vector3:
	return Vector3(grid.x * tile_size, 0, grid.y * tile_size)
