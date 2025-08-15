extends Room

class_name PowerGenerator

var meshes: Dictionary = {
	1: MeshLink._meshes.LIVING_ROOM_1L,
	2: MeshLink._meshes.LIVING_ROOM_2L,
	3: MeshLink._meshes.LIVING_ROOM_3L
}

var room_name: String = "Power Generator"


func _constructor() -> void:
	var params: WorkingPoolParameters = WorkingPoolParameters._default()
	working_spots = WorkingPool.new(params)
