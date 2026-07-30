extends RefCounted
class_name Inventory

var items: Array = []
var max_slots: int = 20

const RARITY_COLORS: Dictionary = {
	"Common": Color.WHITE,
	"Uncommon": Color.LAWN_GREEN,
	"Rare": Color.CORNFLOWER_BLUE,
	"Legendary": Color.GOLD
}

func add_item(item: Dictionary) -> bool:
	if items.size() >= max_slots:
		return false
	items.append(item)
	return true

func remove_item(index: int) -> Dictionary:
	if index >= 0 and index < items.size():
		return items.pop_at(index)
	return {}

func get_items_by_rarity(rarity: String) -> Array:
	var result = []
	for item in items:
		if item.get("rarity", "") == rarity:
			result.append(item)
	return result

func to_array() -> Array:
	return items.duplicate()
