class_name Heavy
extends Enemy

var _last_position: Vector2

func _setup_state_machine() -> void:
	state_machine.initialize(self)
	state_machine.setup_states()
	_last_position = global_position
	state_machine.start("Idle")

func _ready() -> void:
	super()
	weapon_component.attack_finished.connect(_on_attack_finished)

func _physics_process(delta: float) -> void:
	var previous_position := _last_position
	super._physics_process(delta)
	_try_start_patrol(previous_position)
	_last_position = global_position

func _try_start_patrol(previous_position: Vector2) -> void:
	if not is_on_floor():
		return

	if global_position.is_equal_approx(previous_position):
		return

	var state_name := state_machine.current_state.name
	if state_name in ["Patrol", "Hurt", "Dead", "Attack", "Chase"]:
		return
	state_machine.change_state("Patrol")
	
func _on_detection_success() -> void:
	state_machine.change_state("Chase")

func _on_detection_lost() -> void:
	state_machine.change_state("Patrol")
