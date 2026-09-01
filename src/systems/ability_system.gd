extends Node
class_name AbilitySystem

var display_name: String = "AbilitySystem"
var abilities: Dictionary = {}

const RESONANCE_WHEEL: Array = ["Ember", "Gale", "Hollow", "Tide", "Root", "Iron", "Chorus"]

func _ready():
	register_ability(Ability.new("ember_strike", "Ember Strike", 50.0, "Ember", 1, "A searing blade of lattice flame."))
	register_ability(Ability.new("gale_dash", "Gale Dash", 40.0, "Gale", 1, "Surge forward on a wind current."))
	register_ability(Ability.new("hollow_drain", "Hollow Drain", 60.0, "Hollow", 1, "Siphon life through the void."))
	register_ability(Ability.new("tide_heal", "Tide Heal", 60.0, "Tide", 1, "Restore health with flowing lattice."))
	register_ability(Ability.new("root_bind", "Root Bind", 45.0, "Root", 1, "Entangle enemies in living lattice."))
	register_ability(Ability.new("iron_shield", "Iron Shield", 55.0, "Iron", 1, "Raise a barrier of ferrous will."))
	register_ability(Ability.new("chorus_blast", "Chorus Blast", 70.0, "Chorus", 1, "Unleash harmonic destruction."))

func register_ability(ability: Ability):
	abilities[ability.ability_id] = ability

static func resonance_distance(type_a: String, type_b: String) -> int:
	var idx_a = RESONANCE_WHEEL.find(type_a)
	var idx_b = RESONANCE_WHEEL.find(type_b)
	if idx_a == -1 or idx_b == -1:
		return 3
	var dist = abs(idx_a - idx_b)
	return min(dist, 7 - dist)

func resolve_cost(ability_id: String, actor_resonance: String) -> float:
	if not abilities.has(ability_id):
		return 9999.0
	var ability = abilities[ability_id]
	var dist = resonance_distance(actor_resonance, ability.resonance_type)
	var mult = 1.0
	if dist == 0:
		mult = 1.4
	elif dist == 1 or dist == 6:
		mult = 1.0
	elif dist == 2 or dist == 5:
		mult = 0.8
	elif dist == 3:
		mult = 0.6
	return ability.base_lc_cost * mult

func cast(ability_id: String, actor: Actor) -> bool:
	if not abilities.has(ability_id):
		return false
	var cost = resolve_cost(ability_id, actor.resonance)
	if actor.consume_lc(cost):
		_apply_effect(ability_id, actor)
		return true
	return false

func _apply_effect(ability_id: String, actor: Actor):
	match ability_id:
		"iron_shield":
			actor.shield_active = true
			actor.shield_duration = 5.0
		"tide_heal":
			actor.heal(25 + actor.attunement * 3)

class Ability:
	var ability_id: String
	var ability_name: String
	var base_lc_cost: float
	var resonance_type: String
	var tier: int
	var description: String

	func _init(id: String, n: String, cost: float, res: String, t: int, desc: String):
		ability_id = id
		ability_name = n
		base_lc_cost = cost
		resonance_type = res
		tier = t
		description = desc
