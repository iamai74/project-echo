class_name ConnectionData
extends Resource

enum Side { TOP, BOTTOM, RIGHT, LEFT }

@export var id: StringName
@export var side: Side
@export var position: Vector2i
@export var size: Vector2i
