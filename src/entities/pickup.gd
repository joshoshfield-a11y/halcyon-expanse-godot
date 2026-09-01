extends Area3D
class_name Pickup

var kind: String = "lc"       # "lc" or "hp"
var amount: float = 60.0
var bob_phase: float = 0.0
var base_y: float = 0.6
var mesh_inst: MeshInstance3D

static func spawn(parent: Node, pos: Vector3, p_kind: String, p_amount: float) -> Pickup:
	var pk = Pickup.new()
	pk.kind = p_kind
	pk.amount = p_amount
	parent.add_child(pk)
	pk.global_position = pos + Vector3(0, 0.6, 0)
	return pk

func _ready():
	add_to_group("pickups")
	collision_layer = 8          # Items layer
	collision_mask = 2           # Player layer
	monitoring = true
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.0
	shape.shape = sphere
	add_child(shape)
	mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if kind == "lc":
		var m = BoxMesh.new()
		m.size = Vector3(0.38, 0.55, 0.38)
		mesh_inst.mesh = m
		mesh_inst.rotation.z = PI / 4
		mat.albedo_color = Color(0.3, 0.9, 1.0)
		mat.emission = Color(0.2, 0.7, 1.0)
	else:
		var m2 = SphereMesh.new()
		m2.radius = 0.3
		m2.height = 0.6
		mesh_inst.mesh = m2
		mat.albedo_color = Color(1.0, 0.35, 0.4)
		mat.emission = Color(1.0, 0.2, 0.25)
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	bob_phase = randf() * TAU
	base_y = global_position.y
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	bob_phase += delta * 3.0
	if mesh_inst:
		mesh_inst.position.y = sin(bob_phase) * 0.15 + 0.1
		mesh_inst.rotation.y += delta * 2.0
	# magnet
	var player = get_tree().get_first_node_in_group("player")
	if player and not player.dead:
		var d = global_position.distance_to(player.global_position)
		if d < 4.5:
			global_position = global_position.move_toward(player.global_position + Vector3(0, 0.6, 0), delta * (9.0 - d))

func _on_body_entered(body):
	if body is PlayerController and not body.dead:
		if kind == "lc":
			body.lattice_charge = min(body.lattice_charge + amount, body.lattice_charge_max())
			Juice.damage_text(get_parent(), global_position, "+%d LC" % int(amount), Color(0.4, 0.9, 1.0))
		else:
			body.heal(int(amount))
			Juice.damage_text(get_parent(), global_position, "+%d HP" % int(amount), Color(0.5, 1.0, 0.5))
		Juice.burst(get_parent(), global_position, Color(0.8, 1.0, 1.0), 10, 3.0, 0.35, 0.06)
		queue_free()
