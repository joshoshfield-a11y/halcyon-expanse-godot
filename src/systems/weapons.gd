extends RefCounted
class_name WeaponDB

# kind: "melee" | "ranged"
const WEAPONS: Dictionary = {
	"ember_blade": {"name": "Ember Blade", "kind": "melee", "dmg": 1.0, "cd": 0.45, "range": 3.0,
		"knock": 7.0, "launch": 2.0, "color": Color(1.0, 0.5, 0.15), "mesh": "sword", "icon": "icon_sword"},
	"gale_staff": {"name": "Gale Staff", "kind": "ranged", "dmg": 0.85, "cd": 0.5, "bolt_speed": 24.0,
		"color": Color(0.5, 0.8, 1.0), "mesh": "staff", "icon": "icon_staff"},
	"void_reaper": {"name": "Void Reaper", "kind": "melee", "dmg": 1.6, "cd": 0.7, "range": 3.5,
		"knock": 11.0, "launch": 3.0, "color": Color(0.7, 0.3, 1.0), "mesh": "scythe", "icon": "icon_scythe"},
	"tide_hammer": {"name": "Tide Hammer", "kind": "melee", "dmg": 2.3, "cd": 0.95, "range": 2.8,
		"knock": 16.0, "launch": 5.0, "color": Color(0.2, 0.7, 0.9), "mesh": "hammer", "icon": "icon_hammer"},
	"chorus_bow": {"name": "Chorus Bow", "kind": "ranged", "dmg": 1.3, "cd": 0.8, "bolt_speed": 30.0,
		"color": Color(1.0, 0.85, 0.3), "mesh": "bow", "icon": "icon_bow"},
}

static func get_w(wid: String) -> Dictionary:
	return WEAPONS.get(wid, WEAPONS["ember_blade"])

static func random_id(rng: RandomNumberGenerator = null) -> String:
	var keys = WEAPONS.keys()
	if rng:
		return keys[rng.randi_range(0, keys.size() - 1)]
	return keys[randi_range(0, keys.size() - 1)]

# Builds the weapon mesh into the rig's right hand.
static func attach(rig: Dictionary, wid: String) -> MeshInstance3D:
	var w = get_w(wid)
	var holder: Node3D = rig["arm_r"]
	var old = holder.get_node_or_null("WeaponMesh")
	if old:
		old.queue_free()
	var root = Node3D.new()
	root.name = "WeaponMesh"
	holder.add_child(root)
	root.position = Vector3(0, -0.62, 0.1)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = w["color"]
	mat.emission_enabled = true
	mat.emission = w["color"]
	mat.emission_energy_multiplier = 1.4
	mat.metallic = 0.7
	mat.roughness = 0.3
	var grip = StandardMaterial3D.new()
	grip.albedo_color = Color(0.15, 0.13, 0.12)
	grip.roughness = 0.8
	match w["mesh"]:
		"sword":
			_add_box(root, Vector3(0.05, 0.3, 0.05), Vector3(0, 0, 0), grip)
			_add_box(root, Vector3(0.07, 0.75, 0.03), Vector3(0, -0.5, 0), mat)
			_add_box(root, Vector3(0.2, 0.05, 0.06), Vector3(0, -0.14, 0), mat)
		"staff":
			_add_box(root, Vector3(0.05, 1.1, 0.05), Vector3(0, -0.3, 0), grip)
			var orb = MeshInstance3D.new()
			var sm = SphereMesh.new()
			sm.radius = 0.12
			sm.height = 0.24
			orb.mesh = sm
			orb.material_override = mat
			root.add_child(orb)
			orb.position = Vector3(0, -0.95, 0)
		"scythe":
			_add_box(root, Vector3(0.05, 1.2, 0.05), Vector3(0, -0.35, 0), grip)
			var blade = _add_box(root, Vector3(0.5, 0.07, 0.03), Vector3(0.22, -0.92, 0), mat)
			blade.rotation.z = 0.35
		"hammer":
			_add_box(root, Vector3(0.06, 0.85, 0.06), Vector3(0, -0.2, 0), grip)
			_add_box(root, Vector3(0.34, 0.22, 0.22), Vector3(0, -0.68, 0), mat)
		"bow":
			var limb = _add_box(root, Vector3(0.05, 0.8, 0.04), Vector3(0, -0.3, 0), mat)
			limb.rotation.z = 0.0
			_add_box(root, Vector3(0.02, 0.72, 0.02), Vector3(0.1, -0.3, 0), grip)
	return _first_mesh(root)

static func _first_mesh(n: Node) -> MeshInstance3D:
	for c in n.get_children():
		if c is MeshInstance3D:
			return c
	return null

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	parent.add_child(mi)
	mi.position = pos
	return mi
