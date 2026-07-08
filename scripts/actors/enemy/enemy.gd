class_name Enemy
extends Actor

@onready var detection_component: DetectionComponent = $DetectionComponent
@export var debug_name: String = "Enemy"
var target_player: Player = null

func _ready() -> void:
	super()
	_setup_components()
	_setup_state_machine()
	detection_component.player_detected.connect(_on_player_detected)
	detection_component.player_lost.connect(_on_player_lost)
	
func _setup_components() -> void:
	# Input есть только у Player
	pass
	
func _setup_state_machine() -> void:
	state_machine.initialize(self)
	state_machine.setup_states()

	state_machine.start("Idle")

func _on_player_detected(player: Player) -> void:
	target_player = player
	_on_detection_success()

func _on_player_lost() -> void:
	target_player = null
	_on_detection_lost()

func _on_detection_success() -> void:
	pass

func _on_detection_lost() -> void:
	pass
	
func _process(delta: float) -> void:
	state_machine.update(delta)
	
func is_attacking() -> bool:
	var result := weapon_component.is_attacking()
	return result

func _on_attack_finished(attack: AttackDefinition) -> void:
	state_machine.handle_attack_finished(attack)
