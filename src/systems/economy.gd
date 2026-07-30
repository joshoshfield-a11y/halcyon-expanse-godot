extends Node
class_name Economy

var name: String = "Economy"
var compact_scrip: float = 100.0
var ledger_mark: float = 50.0
var exchange_rate: float = 1.0
var rate_fluctuation: float = 0.0
var faction_control: Dictionary = {}

func _ready():
	_update_rate()
	faction_control["VeyraPrime"] = "Luminous Concord"
	faction_control["Ashduin"] = "Ashborn Remnant"
	faction_control["IronMeridian"] = "Ferro Compact"
	faction_control["TwoRivers"] = "Tidebound"
	faction_control["HollowAnchor"] = "Hollow Choir"

func _update_rate():
	var base = 1.0 + (randf() - 0.5) * 0.3
	var control_bonus = 0.0
	for sys in faction_control.values():
		if sys == "Ferro Compact":
			control_bonus += 0.05
	exchange_rate = clamp(base + control_bonus, 0.5, 1.5)

func exchange(amount: float, from_currency: String, to_currency: String) -> float:
	if from_currency == to_currency:
		return amount
	var rate = exchange_rate
	if from_currency == "CS" and to_currency == "LM":
		return amount * rate
	elif from_currency == "LM" and to_currency == "CS":
		return amount / rate
	return 0.0

func update(dt: float):
	if randf() < dt * 0.1:
		_update_rate()
