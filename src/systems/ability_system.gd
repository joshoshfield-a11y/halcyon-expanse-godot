extends Node
class_name AbilitySystem

var display_name: String = "AbilitySystem"
var abilities: Dictionary = {}

const RESONANCE_WHEEL: Array = ["Ember", "Gale", "Hollow", "Tide", "Root", "Iron", "Chorus"]

func _ready():
	register_ability(Ability.new("ember_strike", "Ember Strike", 50.0, "Ember", 1, "Cone of lattice flame in front of you."))
	register_ability(Ability.new("gale_dash", "Gale Dash", 40.0, "Gale", 1, "Surge forward, phasing through danger."))
	register_ability(Ability.new("hollow_drain", "Hollow Drain", 60.0, "Hollow", 1, "Siphon life from all nearby enemies."))
	register_ability(Ability.new("tide_heal", "Tide Heal", 60.0, "Tide", 1, "Restore health with flowing lattice."))
	register_ability(Ability.new("root_bind", "Root Bind", 45.0, "Root", 1, "Slow all nearby enemies to a crawl."))
	register_ability(Ability.new("iron_shield", "Iron Shield", 55.0, "Iron", 1, "Barrier absorbs 70% damage for 5s."))
	register_ability(Ability.new("chorus_blast", "Chorus Blast", 70.0, "Chorus", 1, "Massive harmonic detonation around you."))

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

func get_ability(ability_id: String) -> Ability:
	return abilities.get(ability_id)

func cast(ability_id: String, actor: Actor) -> bool:
	if not abilities.has(ability_id):
		return false
	var cost = resolve_cost(ability_id, actor.resonance)
	if actor.consume_lc(cost):
		_apply_effect(ability_id, actor)
		return true
	return false

func _main() -> Node:
	return get_node_or_null("/root/Main")

func _nearby_enemies(pos: Vector3, radius: float) -> Array:
	var out = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and e.global_position.distance_to(pos) <= radius:
			out.append(e)
	return out

func _apply_effect(ability_id: String, actor: Actor):
	var main = _main()
	var att = actor.attunement
	match ability_id:
		"ember_strike":
			var dmg = 50 + att * 5
			var fwd = Vector3.FORWARD
			if actor is PlayerController:
				fwd = actor.facing.normalized()
			for e in _nearby_enemies(actor.global_position, 5.0):
				var to_e = e.global_position - actor.global_position
				to_e.y = 0
				if to_e.length() > 0.01 and fwd.angle_to(to_e.normalized()) < 1.0:
					e.take_damage(dmg)
					e.apply_knockback(to_e.normalized(), 8.0, 2.5)
					if main:
						Juice.damage_text(main, e.global_position, str(dmg), Color(1, 0.55, 0.15))
			if main:
				var c = actor.global_position + fwd * 2.5 + Vector3(0, 1, 0)
				Juice.burst(main, c, Color(1, 0.45, 0.1), 30, 7.0, 0.5, 0.11)
				main.add_shake(0.35)
		"gale_dash":
			if actor is PlayerController:
				actor.dash_cooldown = 0.0
				actor.do_dash()
		"hollow_drain":
			var drained = 0
			for e in _nearby_enemies(actor.global_position, 6.0):
				var d = 25 + att * 3
				e.take_damage(d)
				drained += d
				if main:
					Juice.damage_text(main, e.global_position, str(d), Color(0.7, 0.3, 1.0))
			actor.heal(int(drained * 0.5))
			if main:
				Juice.ring(main, actor.global_position, Color(0.55, 0.15, 0.85), 6.0, 0.5)
		"tide_heal":
			var amt = 30 + att * 4
			actor.heal(amt)
			if main:
				Juice.damage_text(main, actor.global_position, "+%d" % amt, Color(0.4, 1, 0.7))
				Juice.burst(main, actor.global_position + Vector3(0, 1, 0), Color(0.3, 0.9, 0.9), 22, 3.5, 0.7, 0.08)
		"root_bind":
			for e in _nearby_enemies(actor.global_position, 7.0):
				e.apply_slow(0.25, 4.0)
				if main:
					Juice.burst(main, e.global_position, Color(0.3, 0.8, 0.3), 10, 2.5, 0.5, 0.07)
			if main:
				Juice.ring(main, actor.global_position, Color(0.3, 0.8, 0.3), 7.0, 0.5)
		"iron_shield":
			actor.shield_active = true
			actor.shield_duration = 5.0
			if main:
				Juice.ring(main, actor.global_position, Color(0.6, 0.65, 0.8), 3.0, 0.4)
		"chorus_blast":
			var dmg2 = 70 + att * 8
			for e in _nearby_enemies(actor.global_position, 8.0):
				var to_e2 = e.global_position - actor.global_position
				to_e2.y = 0
				e.take_damage(dmg2)
				if to_e2.length() > 0.01:
					e.apply_knockback(to_e2.normalized(), 12.0, 5.0)
				if main:
					Juice.damage_text(main, e.global_position, str(dmg2), Color(1, 0.95, 0.3), true)
			if main:
				Juice.ring(main, actor.global_position, Color(1, 0.9, 0.2), 8.0, 0.6)
				Juice.burst(main, actor.global_position + Vector3(0, 1, 0), Color(1, 0.85, 0.2), 48, 9.0, 0.7, 0.12)
				main.add_shake(0.7)
				main.hit_stop(0.09, 0.1)
				main.zoom_punch(3.0, 0.45)

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
