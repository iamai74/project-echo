class_name DetectionComponent
extends Area2D

signal player_detected(player: Player)
signal player_lost()

var detected_player: Player

func _ready():
	print("detection ready")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if not _check_is_player(area):
		return
	print("detect player")
	if detected_player:
		return
	detected_player = area.get_parent()
	player_detected.emit(detected_player)

func _on_area_exited(area: Area2D) -> void:
	if not _check_is_player(area):
		return
	print("player lose")
	if area.get_parent() != detected_player:
		return
	detected_player = null
	player_lost.emit()

func _check_is_player(area: Area2D) -> bool:
	if not area is HurtboxComponent:
		return false
	var actor := area.get_parent()
	return actor is Player
