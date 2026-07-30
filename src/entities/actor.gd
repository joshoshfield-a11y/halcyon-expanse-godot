extends GameEntity
class_name Actor

@export var resonance: String = "Ember"
@export var attunement: int = 1
@export var lattice_charge: float = 500.0
@export var lattice_debt: float = 0.0
@export var is_player: bool = false
@export var shield_active: bool = false
@export var shield_duration: float = 0.0
@export var xp: int = 0
@export var skill_points: int = 0

const RESONANCE_WHEEL: Array = ["Ember", "Gale", "Hollow", "Tide", "Root", "Iron", "Chorus"]
const LC_MAX_BASE: float = 1000.0
const LC_REGEN_BASE: float = 2.0
const DEBT_RATE: float = 0.03

var in_hollowed_zone: bool = false
var inventory: Inventory = null
var equipment: Dictionary = {}

func _init():
	hp = 100
	max_hp = 100
	inventory = Inventory.new()

func lattice_charge_max() -> float:
	var eq_bonus = 0.0
	for slot in equipment.values():
		if slot is Dictionary and slot.has("lc_bonus"):
			eq_bonus += slot["lc_bonus"]
	return LC_MAX_BASE + (attunement - 1) * 50.0 + eq_bonus

func consume_lc(amount: float) -> bool:
	if in_hollowed_zone:
		return false
	if lattice_charge >= amount:
		lattice_charge -= amount
		return true
	return false

func regenerate_lc(dt: float):
	if in_hollowed_zone:
		lattice_charge = 0.0
		return
	var regen = LC_REGEN_BASE + (attunement - 1) * 0.5
	for slot in equipment.values():
		if slot is Dictionary and slot.has("lc_regen"):
			regen += slot["lc_regen"]
	lattice_charge = min(lattice_charge + regen * dt, lattice_charge_max())

func enter_hollowed_zone():
	in_hollowed_zone = true
	lattice_charge = 0.0

func exit_hollowed_zone():
	in_hollowed_zone = false

func update(dt: float):
	regenerate_lc(dt)
	lattice_debt += lattice_charge * DEBT_RATE * dt / 3600.0
	if shield_active:
		shield_duration -= dt
		if shield_duration <= 0:
			shield_active = false

func get_damage_bonus() -> int:
	var bonus = attunement * 2
	for slot in equipment.values():
		if slot is Dictionary and slot.has("damage_bonus"):
			bonus += slot["damage_bonus"]
	return bonus

func get_defense_bonus() -> int:
	var bonus = 0
	for slot in equipment.values():
		if slot is Dictionary and slot.has("defense_bonus"):
			bonus += slot["defense_bonus"]
	return bonus
