class_name Player
extends Actor

@onready var input_component: InputComponent = $InputComponent
@export var debug_name: String = "Player"

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
	
func get_input() -> InputComponent:
	return input_component

func is_player() -> bool:
	return true
