extends CharacterBody3D
class_name GameEntity

@export var entity_kind: String = "generic"
@export var hp: int = 100
@export var max_hp: int = 100
@export var data: Dictionary = {}

var dead: bool = false

func _init():
	pass

func take_damage(amount: int) -> int:
	hp -= amount
	if hp <= 0:
		hp = 0
		dead = true
	return hp

func heal(amount: int):
	hp = min(hp + amount, max_hp)

func to_dict() -> Dictionary:
	return {
		"kind": entity_kind,
		"hp": hp,
		"max_hp": max_hp,
		"position": [global_position.x, global_position.y, global_position.z],
		"data": data
	}
