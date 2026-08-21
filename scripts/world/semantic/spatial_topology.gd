class_name SpatialTopology
extends RefCounted

enum Shape { SINGLE, TOP, BOTTOM, LEFT, RIGHT, FULL }
enum Corner { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, TOP, BOTTOM, LEFT, RIGHT, ALL, NO }

var shape: Shape
var corner: Corner
