class_name HealthComponent
extends Node

## Signal emitted when health changes
signal health_changed(current: int, max: int)
## Signal emitted when entity takes damage
signal damaged(amount: int)
## Signal emitted when entity is healed
signal healed(amount: int)
## Signal emitted when entity dies
signal died

var current_health: int = 100
var max_health: int = 100


func _ready():
	health_changed.emit(current_health, max_health)


func initialize(max_hp: int) -> void:
	max_health = max_hp
	current_health = max_hp
	health_changed.emit(current_health, max_health)


func take_damage(attack_data: AttackData) -> void:
	var damage = attack_data.damage
	if damage <= 0 or not is_alive():
		return
	current_health = max(0, current_health - damage)
	damaged.emit(damage)
	health_changed.emit(current_health, max_health)

	if not is_alive():
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return

	current_health = min(max_health, current_health + amount)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)


func set_max_health(value: int) -> void:
	max_health = value
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

	if not is_alive():
		died.emit()


func is_alive() -> bool:
	return current_health > 0


func get_health_percentage() -> float:
	if max_health == 0:
		return 0.0
	return float(current_health) / float(max_health)
