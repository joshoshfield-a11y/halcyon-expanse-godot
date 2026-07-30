extends CanvasLayer
class_name MobileControls

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var attack_btn: Button = $AttackBtn
@onready var ability_btns: HBoxContainer = $AbilityBar

var joystick_active: bool = false
var joystick_center: Vector2
var joystick_radius: float = 60.0
var joystick_vector: Vector2 = Vector2.ZERO

var touch_id: int = -1

func _ready():
	joystick_center = joystick_base.global_position + joystick_base.size / 2
	attack_btn.pressed.connect(_on_attack_pressed)
	for i in range(7):
		var btn = ability_btns.get_child(i) if i < ability_btns.get_child_count() else null
		if btn:
			btn.pressed.connect(_on_ability_pressed.bind(i))
	# Hide on desktop
	if not OS.has_feature("android") and not OS.has_feature("ios"):
		visible = false

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_joystick(event.position):
				joystick_active = true
				touch_id = event.index
				_update_knob(event.position)
		else:
			if event.index == touch_id:
				joystick_active = false
				touch_id = -1
				joystick_vector = Vector2.ZERO
				joystick_knob.position = joystick_base.size / 2 - joystick_knob.size / 2
	elif event is InputEventScreenDrag:
		if event.index == touch_id and joystick_active:
			_update_knob(event.position)

func _is_in_joystick(pos: Vector2) -> bool:
	return pos.distance_to(joystick_center) < joystick_radius * 2

func _update_knob(pos: Vector2):
	var dir = pos - joystick_center
	var dist = min(dir.length(), joystick_radius)
	joystick_vector = dir.normalized() * (dist / joystick_radius)
	var knob_pos = joystick_center + dir.normalized() * dist - joystick_knob.size / 2
	joystick_knob.global_position = knob_pos

func _on_attack_pressed():
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")

func _on_ability_pressed(index: int):
	var action = "ability_%d" % (index + 1)
	Input.action_press(action)
	await get_tree().create_timer(0.1).timeout
	Input.action_release(action)
