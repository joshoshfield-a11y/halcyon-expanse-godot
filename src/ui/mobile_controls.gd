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
var look_id: int = -1
var look_last: Vector2 = Vector2.ZERO
var look_accum: Vector2 = Vector2.ZERO
var dash_btn: Button
var pause_btn: Button
var pause_debounce: float = 0.0

const ABILITY_SHORT: Array = ["EMB", "GAL", "HOL", "TID", "ROT", "IRN", "CHO"]
const ABILITY_IDS: Array = ["ember_strike", "gale_dash", "hollow_drain", "tide_heal",
					"root_bind", "iron_shield", "chorus_blast"]

func _ready():
	joystick_center = joystick_base.global_position + joystick_base.size / 2
	attack_btn.pressed.connect(_on_attack_pressed)
	for i in range(7):
		var btn = ability_btns.get_child(i) if i < ability_btns.get_child_count() else null
		if btn:
			btn.text = ABILITY_SHORT[i]
			btn.pressed.connect(_on_ability_pressed.bind(i))

	# dash button (code-added so the scene file stays untouched)
	dash_btn = Button.new()
	dash_btn.text = "DASH"
	dash_btn.add_theme_font_size_override("font_size", 22)
	dash_btn.custom_minimum_size = Vector2(110, 110)
	dash_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dash_btn.position = Vector2(-310, -310)
	dash_btn.pressed.connect(_on_dash_pressed)
	add_child(dash_btn)

	# pause button
	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.add_theme_font_size_override("font_size", 22)
	pause_btn.custom_minimum_size = Vector2(64, 64)
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.position = Vector2(-84, 20)
	pause_btn.pressed.connect(_on_pause_pressed)
	add_child(pause_btn)

	if not OS.has_feature("android") and not OS.has_feature("ios"):
		visible = false

func _process(delta):
	pause_debounce -= delta
	# cooldown dimming on ability buttons
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	for i in range(min(7, ability_btns.get_child_count())):
		var btn = ability_btns.get_child(i)
		var cd = player.ability_cooldowns.get(ABILITY_IDS[i], 0.0)
		if cd > 0:
			btn.modulate = Color(0.4, 0.4, 0.45)
			btn.text = "%d" % int(ceil(cd))
		else:
			btn.modulate = Color(1, 1, 1)
			btn.text = ABILITY_SHORT[i]
	dash_btn.modulate = Color(0.5, 0.5, 0.55) if player.dash_cooldown > 0 else Color(1, 1, 1)

func consume_look_delta() -> Vector2:
	var d = look_accum
	look_accum = Vector2.ZERO
	return d

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# gameplay buttons first — raw touch events, so they fire even while
			# other fingers are down (touch->mouse emulation only converts finger 1)
			if _press_button_at(event.position):
				return
			if _is_in_joystick(event.position):
				joystick_active = true
				touch_id = event.index
				_update_knob(event.position)
			elif event.position.x > get_viewport().get_visible_rect().size.x * 0.5 and look_id == -1:
				look_id = event.index
				look_last = event.position
		else:
			if event.index == touch_id:
				joystick_active = false
				touch_id = -1
				joystick_vector = Vector2.ZERO
				joystick_knob.position = joystick_base.size / 2 - joystick_knob.size / 2
			if event.index == look_id:
				look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == touch_id and joystick_active:
			_update_knob(event.position)
		elif event.index == look_id:
			look_accum += event.position - look_last
			look_last = event.position

func _press_button_at(pos: Vector2) -> bool:
	if not visible:
		return false
	if attack_btn.get_global_rect().has_point(pos):
		_flash(attack_btn)
		_on_attack_pressed()
		return true
	if dash_btn and dash_btn.get_global_rect().has_point(pos):
		_flash(dash_btn)
		_on_dash_pressed()
		return true
	if pause_btn and pause_btn.get_global_rect().has_point(pos):
		_flash(pause_btn)
		_on_pause_pressed()
		return true
	for i in range(min(7, ability_btns.get_child_count())):
		var b = ability_btns.get_child(i)
		if b.get_global_rect().has_point(pos):
			_flash(b)
			_on_ability_pressed(i)
			return true
	return false

func _flash(b: Button):
	b.modulate = Color(1.6, 1.6, 1.6)
	var tw = b.create_tween()
	tw.tween_property(b, "modulate", Color(1, 1, 1), 0.18)

func _is_in_joystick(pos: Vector2) -> bool:
	return pos.distance_to(joystick_center) < joystick_radius * 2

func _update_knob(pos: Vector2):
	var dir = pos - joystick_center
	var dist = min(dir.length(), joystick_radius)
	joystick_vector = dir.normalized() * (dist / joystick_radius) if dir.length() > 0.01 else Vector2.ZERO
	joystick_knob.global_position = joystick_center + dir.normalized() * dist - joystick_knob.size / 2 if dir.length() > 0.01 else joystick_center - joystick_knob.size / 2

func _on_attack_pressed():
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")

func _on_ability_pressed(index: int):
	var action = "ability_%d" % (index + 1)
	Input.action_press(action)
	await get_tree().create_timer(0.1).timeout
	Input.action_release(action)

func _on_dash_pressed():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("do_dash"):
		player.do_dash()

func _on_pause_pressed():
	if pause_debounce > 0:
		return
	pause_debounce = 0.4
	Input.action_press("pause_menu")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("pause_menu")
