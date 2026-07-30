extends Actor
class_name PlayerController

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0

var combat: CombatSystem = null
var ability_sys: AbilitySystem = null
var attack_cooldown: float = 0.0
var ability_cooldowns: Dictionary = {}
var facing: Vector3 = Vector3.FORWARD

func _ready():
	is_player = true
	name = "Player"
	add_to_group("player")
	# Find systems
	var main = get_node_or_null("/root/Main")
	if main:
		combat = main.get_node_or_null("CombatSystem")
		ability_sys = main.get_node_or_null("AbilitySystem")

func _physics_process(delta):
	if dead:
		return
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_abilities(delta)
	attack_cooldown -= delta
	for k in ability_cooldowns.keys():
		ability_cooldowns[k] -= delta

func _handle_movement(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		facing = input_dir
		velocity = input_dir * speed
		# Rotate mesh to face direction
		if $MeshInstance3D:
			$MeshInstance3D.rotation.y = atan2(facing.x, facing.z)
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func _handle_combat(delta):
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0:
		attack_cooldown = 0.5
		_perform_melee_attack()

func _perform_melee_attack():
	if combat == null:
		return
	# Raycast or area check for enemies in front
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 2.0
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1 << 2  # Layer 3 (Enemies)
	var space_state = get_world_3d().direct_space_state
	var results = space_state.intersect_shape(query, 10)
	for result in results:
		var collider = result["collider"]
		if collider is Enemy and not collider.dead:
			var dmg = combat.melee_attack(self, collider)
			print("Hit ", collider.enemy_type, " for ", dmg, " damage!")
			break

func _handle_abilities(delta):
	var ability_ids = ["ember_strike", "gale_dash", "hollow_drain", "tide_heal",
					"root_bind", "iron_shield", "chorus_blast"]
	for i in range(7):
		if Input.is_action_just_pressed("ability_%d" % (i + 1)):
			var aid = ability_ids[i]
			if not ability_cooldowns.has(aid) or ability_cooldowns[aid] <= 0:
				if ability_sys and ability_sys.cast(aid, self):
					ability_cooldowns[aid] = 2.0
					print("Cast ", aid)
					_spawn_cast_effect(aid)

func _spawn_cast_effect(ability_id: String):
	# Spawn particle effect based on resonance
	var color = Color.ORANGE
	match ability_id:
		"gale_dash": color = Color.LIGHT_BLUE
		"hollow_drain": color = Color.PURPLE
		"tide_heal": color = Color.CYAN
		"root_bind": color = Color.FOREST_GREEN
		"iron_shield": color = Color.GRAY
		"chorus_blast": color = Color.YELLOW
	# In a full implementation, instantiate a particle scene here
