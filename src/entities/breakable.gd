extends StaticBody3D
class_name Breakable

# Supply crate: smack it with melee to break it open.

func _ready():
	add_to_group("breakables")
	collision_layer = 1
	collision_mask = 0

func shatter():
	var main = get_node_or_null("/root/Main")
	if main == null:
		queue_free()
		return
	CharRig.spawn_debris(main, global_position, Color(0.55, 0.4, 0.22), 5, 3.5)
	Juice.burst(main, global_position + Vector3(0, 0.6, 0), Color(0.9, 0.75, 0.4), 14, 4.0, 0.4, 0.08)
	var roll = randf()
	if roll < 0.35:
		Pickup.spawn(main, global_position, "lc", 80)
	elif roll < 0.55:
		Pickup.spawn(main, global_position, "hp", 30)
	elif roll < 0.85:
		var kinds = ["stim", "shield", "oc", "xp"]
		Pickup.spawn(main, global_position, kinds[randi_range(0, 3)], 1)
	else:
		Pickup.spawn(main, global_position, "weapon:" + WeaponDB.random_id(), 0)
	queue_free()
