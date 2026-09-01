extends Node
class_name CombatSystem

var display_name: String = "CombatSystem"

func melee_attack(attacker: Actor, target: GameEntity) -> int:
	var base = 18 + attacker.get_damage_bonus()
	if attacker is PlayerController:
		base += (attacker.level - 1) * 3
	# ±15% variance, 12% crit at 1.8x
	var dmg = int(base * randf_range(0.85, 1.15))
	var crit = randf() < 0.12
	if crit:
		dmg = int(dmg * 1.8)
	if target is Actor and target.shield_active:
		dmg = int(dmg * 0.3)
	target.take_damage(dmg)
	if crit:
		var main = get_node_or_null("/root/Main")
		if main:
			Juice.damage_text(main, target.global_position + Vector3(0, 0.6, 0), "CRIT", Color(1, 0.3, 0.2), true)
	return dmg

func enemy_attack(enemy: Enemy, target: Actor) -> int:
	var dmg = enemy.damage
	var defense = target.get_defense_bonus()
	dmg = max(dmg - defense, 1)
	if target.shield_active:
		dmg = int(dmg * 0.3)
	target.take_damage(dmg)
	return dmg
