## WeaponData and AttackDefinition unit tests.
## Covers: initialize map, lookup by type, missing attack, multiple attacks.
extends GdUnitTestSuite


func _make_attack(type: AttackType.Type, damage_value: int) -> AttackDefinition:
	var def = AttackDefinition.new()
	def.attack_type = type
	def.damage = damage_value
	return def


func test_weapon_data_initialize_builds_map() -> void:
	var weapon = WeaponData.new()
	var light = _make_attack(AttackType.Type.LIGHT, 10)
	var heavy = _make_attack(AttackType.Type.HEAVY, 25)
	var attacks: Array[AttackDefinition] = [light, heavy]
	weapon.attacks = attacks
	weapon.initialize()
	assert_object(weapon.get_attack(AttackType.Type.LIGHT)).is_not_null()
	assert_object(weapon.get_attack(AttackType.Type.HEAVY)).is_not_null()


func test_weapon_data_get_attack_returns_correct_damage() -> void:
	var weapon = WeaponData.new()
	var light = _make_attack(AttackType.Type.LIGHT, 15)
	var attacks: Array[AttackDefinition] = [light]
	weapon.attacks = attacks
	weapon.initialize()
	var found = weapon.get_attack(AttackType.Type.LIGHT)
	assert_object(found).is_not_null()
	assert_int(found.damage).is_equal(15)


func test_weapon_data_get_missing_attack_returns_null() -> void:
	var weapon = WeaponData.new()
	var attacks: Array[AttackDefinition] = []
	weapon.attacks = attacks
	weapon.initialize()
	assert_object(weapon.get_attack(AttackType.Type.SPECIAL)).is_null()


func test_weapon_data_get_attack_types() -> void:
	var weapon = WeaponData.new()
	var light = _make_attack(AttackType.Type.LIGHT, 10)
	var jump = _make_attack(AttackType.Type.JUMP, 20)
	var attacks: Array[AttackDefinition] = [light, jump]
	weapon.attacks = attacks
	weapon.initialize()
	var types = weapon.get_attack_types()
	assert_array(types).contains(AttackType.Type.LIGHT)
	assert_array(types).contains(AttackType.Type.JUMP)
	assert_int(types.size()).is_equal(2)


func test_weapon_data_multiple_attacks() -> void:
	var weapon = WeaponData.new()
	var light = _make_attack(AttackType.Type.LIGHT, 10)
	var heavy = _make_attack(AttackType.Type.HEAVY, 30)
	var jump = _make_attack(AttackType.Type.JUMP, 20)
	var attacks: Array[AttackDefinition] = [light, heavy, jump]
	weapon.attacks = attacks
	weapon.initialize()
	assert_int(weapon.get_attack(AttackType.Type.LIGHT).damage).is_equal(10)
	assert_int(weapon.get_attack(AttackType.Type.HEAVY).damage).is_equal(30)
	assert_int(weapon.get_attack(AttackType.Type.JUMP).damage).is_equal(20)


func test_attack_definition_default_values() -> void:
	var def = AttackDefinition.new()
	assert_int(def.damage).is_equal(10)
	assert_float(def.knockback_force).is_equal(150.0)
	assert_float(def.startup).is_equal(0.08)
	assert_float(def.active).is_equal(0.10)
	assert_float(def.recovery).is_equal(0.12)
	assert_vector(def.hitbox_size).is_equal(Vector2(32, 24))


func test_attack_data_constructor() -> void:
	var data = AttackData.new(25, 300.0, null, Vector2.DOWN)
	assert_int(data.damage).is_equal(25)
	assert_float(data.knockback_force).is_equal(300.0)
	assert_object(data.source).is_null()
	assert_vector(data.direction).is_equal(Vector2.DOWN)


func test_attack_data_defaults() -> void:
	var data = AttackData.new(10)
	assert_int(data.damage).is_equal(10)
	assert_float(data.knockback_force).is_zero()
	assert_object(data.source).is_null()
	assert_vector(data.direction).is_equal(Vector2.ZERO)
