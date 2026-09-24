class_name ConnectionData
extends RefCounted

enum Side { TOP, BOTTOM, RIGHT, LEFT }

var id: StringName
var side: Side
var position: Vector2i
var size: Vector2i
