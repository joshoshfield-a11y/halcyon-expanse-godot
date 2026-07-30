extends Node
class_name CombatSystem

var name: String = "CombatSystem"

func melee_attack(attacker: Actor, target: GameEntity) -> int:
	var dmg = 18 + attacker.get_damage_bonus()
	if target is Actor and target.shield_active:
		dmg = int(dmg * 0.3)
	var remaining = target.take_damage(dmg)
	return dmg

func enemy_attack(enemy: Enemy, target: Actor) -> int:
	var dmg = enemy.damage
	var defense = target.get_defense_bonus()
	dmg = max(dmg - defense, 1)
	if target.shield_active:
		dmg = int(dmg * 0.3)
	target.take_damage(dmg)
	return dmg

func cast_ability(ability_id: String, caster: Actor, target = null) -> bool:
	var ability_sys = caster.get_node_or_null("/root/Main/AbilitySystem")
	if ability_sys == null:
		return false
	var success = ability_sys.cast(ability_id, caster)
	if success and target != null and target is GameEntity:
		match ability_id:
			"ember_strike":
				target.take_damage(50 + caster.attunement * 5)
			"gale_dash":
				pass  # Movement handled by caller
			"hollow_drain":
				var drain = 20 + caster.attunement * 3
				target.take_damage(drain)
				caster.heal(int(drain * 0.5))
			"root_bind":
				if target is Enemy:
					target.move_speed *= 0.3
			"chorus_blast":
				target.take_damage(70 + caster.attunement * 8)
	return success
