class_name ConnectionSide
extends RefCounted

# Append-only: new sides go at the end so serialized integers keep their meaning.
enum Value { TOP, BOTTOM, RIGHT, LEFT }
