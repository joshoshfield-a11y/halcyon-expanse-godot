extends GameEntity
class_name Enemy

@export var enemy_type: String = "Ash Wraith"
@export var behavior_pattern: String = "phase_cycle"
@export var detection_range: float = 8.0
@export var attack_range: float = 1.5
@export var move_speed: float = 2.5
@export var damage: int = 12
@export var xp_value: int = 25
@export var loot_table: Array = []

var state_machine: String = "idle"
var state_timer: float = 0.0
var patrol_target: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0
var phase: int = 0

func _init():
	hp = 80
	max_hp = 80

func update(dt: float, player_pos: Vector3):
	if dead:
		return
	var dist = global_position.distance_to(player_pos)
	state_timer -= dt
	attack_cooldown -= dt

	match behavior_pattern:
		"phase_cycle":
			_update_phase_cycle(dt, dist, player_pos)
		"patrol_loop":
			_update_patrol_loop(dt, dist, player_pos)
		"stealth_ambush":
			_update_stealth_ambush(dt, dist, player_pos)
		"area_pulse":
			_update_area_pulse(dt, dist, player_pos)
		"buff_ally":
			_update_buff_ally(dt, dist, player_pos)
		"swarm_split":
			_update_swarm_split(dt, dist, player_pos)
		_:
			_update_phase_cycle(dt, dist, player_pos)

func _update_phase_cycle(dt: float, dist: float, player_pos: Vector3):
	if dist < detection_range:
		if dist > attack_range:
			var dir = (player_pos - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
		elif attack_cooldown <= 0:
			attack_cooldown = 1.5
			state_machine = "attack"
	else:
		velocity = Vector3.ZERO

func _update_patrol_loop(dt: float, dist: float, player_pos: Vector3):
	if dist < detection_range:
		var dir = (player_pos - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
	else:
		if state_timer <= 0:
			patrol_target = global_position + Vector3(randi() % 10 - 5, 0, randi() % 10 - 5)
			state_timer = 3.0
		var dir = (patrol_target - global_position).normalized()
		velocity = dir * move_speed * 0.5
		move_and_slide()

func _update_stealth_ambush(dt: float, dist: float, player_pos: Vector3):
	if dist < detection_range * 0.5 and attack_cooldown <= 0:
		attack_cooldown = 2.0
		state_machine = "ambush"
		var dir = (player_pos - global_position).normalized()
		velocity = dir * move_speed * 2.0
		move_and_slide()
	else:
		velocity = Vector3.ZERO

func _update_area_pulse(dt: float, dist: float, player_pos: Vector3):
	if state_timer <= 0:
		state_timer = 4.0
		state_machine = "pulse"
	if dist < detection_range:
		var dir = (player_pos - global_position).normalized()
		velocity = dir * move_speed * 0.3
		move_and_slide()

func _update_buff_ally(dt: float, dist: float, player_pos: Vector3):
	if dist < detection_range:
		var dir = (player_pos - global_position).normalized()
		velocity = dir * move_speed * 0.7
		move_and_slide()
	if state_timer <= 0:
		state_timer = 6.0
		state_machine = "buff"

func _update_swarm_split(dt: float, dist: float, player_pos: Vector3):
	if dist < detection_range:
		var dir = (player_pos - global_position).normalized()
		velocity = dir * move_speed * 1.2
		move_and_slide()
		if state_timer <= 0 and hp < max_hp * 0.5:
			state_timer = 8.0
			state_machine = "split"
