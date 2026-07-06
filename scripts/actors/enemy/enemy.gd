class_name Enemy
extends Actor

@export var debug_name: String = "Enemy"

func _ready() -> void:
	super()
	_setup_components()
	_setup_state_machine()
	
func _setup_components() -> void:
	# Input есть только у Player
	pass
	
func _setup_state_machine() -> void:
	state_machine.initialize(self)
	state_machine.setup_states()

	state_machine.start("Idle")
	
func _process(delta: float) -> void:
	state_machine.update(delta)

func is_attacking() -> bool:
	var result := weapon_component.is_attacking()
	return result

func _on_attack_finished(attack: AttackDefinition) -> void:
	state_machine.handle_attack_finished(attack)
