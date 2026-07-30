extends Area3D
class_name HollowedZone

@export var zone_name: String = "Unnamed Zone"
@export var system: String = "VeyraPrime"

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Actor:
		body.enter_hollowed_zone()
		print("[Hollowed] ", body.name, " entered ", zone_name)

func _on_body_exited(body):
	if body is Actor:
		body.exit_hollowed_zone()
		print("[Hollowed] ", body.name, " exited ", zone_name)
