extends Entity

class_name Dweller


const MAX_SPEED = 2.5
var id: String = UUID.v4()

var assigned_room = null
var is_traveling = false

var matrix_position:
	get:
		var grid_map = get_tree().current_scene.find_child("GridMap")
		var z = roundi(position.z/ grid_map.cell_size.z) * -1
		var y = roundi((position.y)/ grid_map.cell_size.y)
		return Vector2i(z, y)

func _ready():
	position.y = 47.095
	
func _process(delta):
	is_outside = true if assigned_room == null else false
	
	if _instructions: # TODO: Improve this mess
		is_traveling = true
		
		var sub_target_position = _target_positions[0] if _target_positions else null
		var instruction = _instructions[0]
		var _vel = global_position.z * MAX_SPEED
		
		# Get direction
		if sub_target_position:
			if global_position.z > sub_target_position.z:
				$Body.scale.x = 1
			elif global_position.z < sub_target_position.z:
				$Body.scale.x = -1
		
		# Process instructions
		match instruction:
			Instructions.ENTER_ELEVATOR:
				if $Timer/t_EnterElevator.is_stopped():
					$Timer/t_EnterElevator.start()
			Instructions.EXIT_ELEVATOR:
				if $Timer/t_ExitElevator.is_stopped():
					$Timer/t_ExitElevator.start()
			Instructions.MOVE_ON_ELEVATOR:
				if $Timer/t_MoveElevator.is_stopped():
					$Timer/t_MoveElevator.start()
			Instructions.MOVE_ON_FLOOR:
				if sub_target_position:
					global_position.y = move_toward(global_position.y, sub_target_position.y, delta * MAX_SPEED)
					global_position.z = move_toward(global_position.z, sub_target_position.z, delta * MAX_SPEED)
		
		if _target_positions and instruction == Instructions.MOVE_ON_FLOOR and \
		global_position.y == sub_target_position.y and \
		global_position.z == sub_target_position.z:
			_target_positions.remove_at(0)
			_instructions.remove_at(0)
	else:
		_target_positions.clear()
		_instructions.clear()
		is_traveling = false

func get_main_parent():
	return get_parent().get_parent().get_parent()

func path_to_room(pos):
	var grid_map = get_tree().current_scene.find_child("GridMap")
	
	var z = roundi(pos.z/ grid_map.cell_size.z) * -1
	var y = roundi((pos.y)/ grid_map.cell_size.y)

	var parent = get_main_parent()
	var matrix: Matrix = parent._matrix
	var max_height = matrix.size.y
	var target_room = matrix.get_room_at(y, z)
	
	if target_room != null:
		return
	
	if _instructions and _instructions[0] == Instructions.MOVE_ON_FLOOR:
		_target_positions.clear()
		_instructions.clear()
	
	var start = Vector2i(matrix_position.x, max_height - matrix_position.y - 1)
	var end = Vector2i(z, max_height - y - 1)
	
	# Unassigned the dweller from the old room
	if assigned_room != null:
		assigned_room._forget_dweller(self)
		
	assigned_room = matrix.get_room_at(end.x, end.y)
	assigned_room._register_dweller(self)
	
	best_path(start, end)
	
	var work_position = assigned_room.get_work_position(self)
	var first_pos = assigned_room.get_first_position()

	_instructions.append(Instructions.MOVE_ON_FLOOR)
	_target_positions.append(Vector3(
		0,
		(max_height - first_pos.y) * grid_map.cell_size.y - 3 + work_position.y,
		(first_pos.x * grid_map.cell_size.z + work_position.x) * -1 
	))


func _on_t_enter_elevator_timeout():
	global_position.x = -1
	_instructions.remove_at(0)


func _on_t_exit_elevator_timeout():
	_instructions.remove_at(0)
	global_position.x = 0


func _on_t_move_elevator_timeout():
	if _target_positions:
		_instructions.remove_at(0)
		global_position.y = _target_positions[0].y
		_target_positions.remove_at(0)
