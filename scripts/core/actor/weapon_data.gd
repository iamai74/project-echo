class_name WeaponData
extends Resource

@export var weapon_name: String
@export var icon: Texture2D
@export var attacks: Array[AttackDefinition]
var _attack_map: Dictionary

func initialize() -> void:
	_attack_map.clear()

	for attack in attacks:
		_attack_map[attack.attack_type] = attack

func get_attack(type: AttackType.Type) -> AttackDefinition:
	return _attack_map.get(type)
