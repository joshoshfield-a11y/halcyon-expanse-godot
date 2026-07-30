extends Node3D
class_name Main

@onready var player_scene: PackedScene = preload("res://scenes/player.tscn")
@onready var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@onready var tile_scene: PackedScene = preload("res://scenes/tile.tscn")

var engine: GameEngine
var state: GameState
var star_systems: StarSystemManager
var ability_sys: AbilitySystem
var combat_sys: CombatSystem
var faction_mgr: FactionManager
var economy: Economy
var bestiary: Bestiary
var codex: Codex
var world_gen: WorldGenerator
var hud: HUD

var current_map: Dictionary = {}
var enemies: Array = []
var tiles: Array = []

func _ready():
	randomize()
	_init_systems()
	_generate_world()
	_spawn_player()
	_spawn_enemies()
	_init_hud()
	print("[Main] Halcyon Expanse initialized")

func _init_systems():
	engine = $GameEngine
	state = engine.state
	star_systems = $StarSystemManager
	ability_sys = $AbilitySystem
	combat_sys = $CombatSystem
	faction_mgr = $FactionManager
	economy = $Economy
	bestiary = $Bestiary
	codex = $Codex
	world_gen = WorldGenerator.new(randi())

func _generate_world():
	var sys_name = star_systems.current_system
	var sys_data = star_systems.get_system_data(sys_name)
	var biome = sys_data.get("biome", "temperate")
	current_map = world_gen.generate_system(sys_name, biome)

	# Clear old tiles
	for t in tiles:
		if is_instance_valid(t):
			t.queue_free()
	tiles.clear()

	# Build 3D tiles
	var tile_size = world_gen.tile_size
	for y in range(current_map["height"]):
		for x in range(current_map["width"]):
			var tile_type = current_map["tiles"][y][x]
			var tile = tile_scene.instantiate()
			tile.position = Vector3(x * tile_size, 0, y * tile_size)
			tile.setup(tile_type, biome)
			$World.add_child(tile)
			tiles.append(tile)

func _spawn_player():
	var spawn = current_map["spawn_points"][0]
	var pos = world_gen.grid_to_world(spawn)
	var player = player_scene.instantiate()
	player.position = pos
	$Entities.add_child(player)
	state.add_entity(player)

	# Set resonance
	player.resonance = "Ember"
	player.attunement = 1
	player.lattice_charge = 500.0

func _spawn_enemies():
	for espawn in current_map.get("enemy_spawns", []):
		if randf() < 0.6:
			var pos = world_gen.grid_to_world(espawn)
			var enemy = enemy_scene.instantiate()
			enemy.position = pos
			# Pick random enemy type
			var types = ["Ash Wraith", "Hollow Stalker", "Iron Drone", "Tide Serpent", "Chorus Knight", "Swarm Mite"]
			enemy.enemy_type = types[randi() % types.size()]
			var entry = bestiary.get_entry(enemy.enemy_type)
			enemy.hp = entry.get("hp", 80)
			enemy.max_hp = enemy.hp
			enemy.damage = entry.get("damage", 12)
			enemy.behavior_pattern = entry.get("pattern", "phase_cycle")
			$Entities.add_child(enemy)
			enemies.append(enemy)
			state.add_entity(enemy)

func _init_hud():
	hud = $HUD
	if state.player:
		hud.set_player(state.player)

func _process(delta):
	if state.player and not state.player.dead:
		for e in enemies:
			if is_instance_valid(e) and not e.dead:
				e.update(delta, state.player.global_position)
				# Enemy attacks
				if e.global_position.distance_to(state.player.global_position) < e.attack_range:
					if e.attack_cooldown <= 0:
						e.attack_cooldown = 1.5
						var dmg = combat_sys.enemy_attack(e, state.player)
						print(e.enemy_type, " hit you for ", dmg, " damage!")
						if state.player.dead:
							print("YOU DIED")
							get_tree().paused = true

	# Clean up dead enemies
	for i in range(enemies.size() - 1, -1, -1):
		if is_instance_valid(enemies[i]) and enemies[i].dead:
			enemies[i].queue_free()
			enemies.remove_at(i)

func warp_to_system(target: String):
	if star_systems.warp(target):
		# Clear entities
		for e in enemies:
			if is_instance_valid(e):
				e.queue_free()
		enemies.clear()
		# Regenerate world
		_generate_world()
		_spawn_enemies()
		# Move player to new spawn
		if state.player:
			var spawn = current_map["spawn_points"][0]
			state.player.position = world_gen.grid_to_world(spawn)
			state.player.velocity = Vector3.ZERO
		print("Warped to ", target)
