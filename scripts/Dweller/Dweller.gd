class_name Dweller
extends Entity


const MAX_SPEED = 1.5


func _ready():
	position.y = 47.095
	position.x = -0.8
	

func _process(_delta: float) -> void:
	pass


func path_to_room(target_room):
	var parent = _get_main_parent()
	var matrix: Matrix = parent._matrix
	var max_height = matrix.size.y
	
	var start = Vector2i(matrix_position.x, max_height - matrix_position.y - 1)
	var end = target_room.positions[0]
	
	# Unassigned the dweller from the old room
	if assigned_room != null:
		assigned_room._forget_dweller(self)
	
	assigned_room = target_room
	assigned_room._register_dweller(self)
	
	map_path = best_path(start, end)
