class_name Player
extends Actor

@onready var input_component: InputComponent = $InputComponent
@export var debug_name: String = "Player"

func _ready() -> void:
	super()
	_setup_components()
	_setup_state_machine()
	weapon_component.attack_finished.connect(_on_attack_finished)
	
func _setup_components() -> void:
	# Input есть только у Player
	pass
	
func _setup_state_machine() -> void:

	state_machine.initialize(self)
	state_machine.setup_states()

	state_machine.start("Idle")
	
func _process(delta: float) -> void:
	state_machine.update(delta)

func _physics_process(delta: float) -> void:
	super(delta)
	
func get_input() -> InputComponent:
	return input_component

func is_player() -> bool:
	return true

func lock_input() -> void:
	input_component.set_input_enabled(false)

func unlock_input() -> void:
	input_component.set_input_enabled(true)
	
func is_attacking() -> bool:
	var result := weapon_component.is_attacking()
	return result

func _on_attack_finished(attack: AttackDefinition) -> void:
	state_machine.handle_attack_finished(attack)
