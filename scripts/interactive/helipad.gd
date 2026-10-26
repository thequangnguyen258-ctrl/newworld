class_name Helipad
extends Node3D

@export var follow_terrain: bool = true

func _ready() -> void:
	if follow_terrain:
		var gh = ModularNatureChunk.get_world_height(global_position.x, global_position.z)
		global_position.y = gh
	if get_child_count() == 0:
		var visual = HelipadBuilder.build_helipad()
		add_child(visual)
