extends RefCounted
class_name TileData

enum TileType {
	FLOOR_GRASS, FLOOR_STONE, FLOOR_ASH, FLOOR_CRYSTAL,
	FLOOR_IRON, FLOOR_WATER, FLOOR_LAVA,
	WALL_STONE, WALL_METAL, WALL_CRYSTAL,
	GATE_SEAM, ITEM_SPAWN, ENEMY_SPAWN, EMPTY
}

const TILE_NAMES: Dictionary = {
	TileType.FLOOR_GRASS: "Grass",
	TileType.FLOOR_STONE: "Stone",
	TileType.FLOOR_ASH: "Ash",
	TileType.FLOOR_CRYSTAL: "Crystal",
	TileType.FLOOR_IRON: "Iron Floor",
	TileType.FLOOR_WATER: "Water",
	TileType.FLOOR_LAVA: "Lava",
	TileType.WALL_STONE: "Stone Wall",
	TileType.WALL_METAL: "Metal Wall",
	TileType.WALL_CRYSTAL: "Crystal Wall",
	TileType.GATE_SEAM: "Seam Gate",
	TileType.ITEM_SPAWN: "Item Spawn",
	TileType.ENEMY_SPAWN: "Enemy Spawn",
	TileType.EMPTY: "Empty"
}

const BIOME_TILESETS: Dictionary = {
	"temperate": [TileType.FLOOR_GRASS, TileType.FLOOR_STONE, TileType.WALL_STONE],
	"volcanic": [TileType.FLOOR_ASH, TileType.FLOOR_LAVA, TileType.WALL_STONE],
	"river": [TileType.FLOOR_GRASS, TileType.FLOOR_WATER, TileType.WALL_STONE],
	"void": [TileType.FLOOR_STONE, TileType.EMPTY, TileType.WALL_METAL],
	"marsh": [TileType.FLOOR_GRASS, TileType.FLOOR_WATER, TileType.WALL_STONE],
	"industrial": [TileType.FLOOR_IRON, TileType.FLOOR_STONE, TileType.WALL_METAL],
	"crystal": [TileType.FLOOR_CRYSTAL, TileType.FLOOR_STONE, TileType.WALL_CRYSTAL],
	"barren": [TileType.FLOOR_ASH, TileType.FLOOR_STONE, TileType.WALL_STONE],
	"reef": [TileType.FLOOR_WATER, TileType.FLOOR_CRYSTAL, TileType.WALL_CRYSTAL]
}

static func is_walkable(tile: int) -> bool:
	return tile in [TileType.FLOOR_GRASS, TileType.FLOOR_STONE, TileType.FLOOR_ASH,
				TileType.FLOOR_CRYSTAL, TileType.FLOOR_IRON, TileType.GATE_SEAM,
				TileType.ITEM_SPAWN, TileType.ENEMY_SPAWN]

static func is_liquid(tile: int) -> bool:
	return tile in [TileType.FLOOR_WATER, TileType.FLOOR_LAVA]

static func get_biome_tiles(biome: String) -> Array:
	return BIOME_TILESETS.get(biome, BIOME_TILESETS["temperate"])
