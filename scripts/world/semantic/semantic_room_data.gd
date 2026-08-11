class_name SemanticRoomData
extends RefCounted

#Data about basic room spatial layers (wall, floor etc.)
var spatial_layers: SpatialLayer = SpatialLayer.new()
#Data about markers (spawn enemies, loot etc)
var markers: MarkerLayer = MarkerLayer.new()
#Data about spesial zones (music. light, fog etc)
var volumes: VolumeLayer = VolumeLayer.new()
