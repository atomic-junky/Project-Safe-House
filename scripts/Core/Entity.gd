extends Node3D

class_name Entity


var _target_positions = []
var _instructions = []
var is_outside: bool = true


# ================ BEST PATH ================
# Calcul the best path to go to a room using astar
# 
# => Fill an array of instructions (instructions)
# => Fill an array of moving points (target_postions)
# 
func best_path(start, end):
	var parent = _get_main_parent()
	var grid_map = get_tree().current_scene.find_child("GridMap")
	var matrix: Matrix = parent._matrix
	var max_height = matrix.size.y
	
	var astar = matrix._build_astar_path()
	
	var start_index = Matrix._vector_to_astar_id(start)
	var end_index = matrix._vector_to_center_room_astar_id(end)
	
	var path = astar.get_id_path(start_index, end_index)
	
	# INSTRUCTIONS from the astar path
	for index in path.size():
		var point_position = astar.get_point_position(path[index])
		var prev_position = astar.get_point_position(path[index - 1]) if index - 1 >= 0 else null
		var next_position = astar.get_point_position(path[index + 1]) if index + 1 < path.size() else null
		
		var current_room = matrix.get_room_at(point_position.x, point_position.x)
		var next_room = matrix.get_room_at(next_position.x, next_position.y) if next_position else null
		var prev_room = matrix.get_room_at(prev_position.x, prev_position.y) if prev_position else null
		
		var first_index_condition = index != 0 or path.size() <= 1
		
		var prev_instruction = _get_prev_instruction()
		
		if current_room is Elevator:
			if prev_room and prev_position.x == point_position.x and prev_position.y != point_position.y and next_room and next_position.y == point_position.y:
				_instructions.append(Instructions.EXIT_ELEVATOR)
				Logger.debug("Exit elevator (1)")
			elif not next_room:
				_instructions.append(Instructions.EXIT_ELEVATOR)
				Logger.debug("Exit elevator (2)")
			elif next_room and next_room is Elevator:
				if next_position.x == point_position.x and next_position.y != point_position.y:
					_instructions.append(Instructions.ENTER_ELEVATOR)
					Logger.debug("Enter elevator (1)")
			elif not prev_room and next_room and next_room is Elevator:
				_instructions.append(Instructions.ENTER_ELEVATOR)
				Logger.debug("Enter elevator (2)")
				
		
		if current_room is Elevator:
			if next_room and next_room is Elevator:
				if (next_room is Elevator and next_position.x != point_position.x and next_position.y == point_position.y):
					_instructions.append(Instructions.MOVE_ON_FLOOR)
					Logger.debug("Move on floor (1)")
				elif next_position.y != point_position.y:
					_instructions.append(Instructions.MOVE_ON_ELEVATOR)
					Logger.debug("Move on elevator")
			else:
				_instructions.append(Instructions.MOVE_ON_FLOOR)
				Logger.debug("Move on floor (2)")
		elif next_room and next_position.y == next_position.y:
			_instructions.append(Instructions.MOVE_ON_FLOOR)
			Logger.debug("Move on floor (3)")
		
		# Append the target position for each time
		if first_index_condition:
			if next_position == null: # If it's the last position
				point_position.x = matrix._vector_to_center_room_position(end).x
			
			var z = point_position.x * grid_map.cell_size.z * -1
			var y = (max_height - point_position.y) * grid_map.cell_size.y - 0.905 - 2 
			_target_positions.append(Vector3(0, y, z))
		
		Logger.debug("Continue")
	
	Logger.debug("========== End of Instructions ==========")

func _get_main_parent():
	return get_parent().get_parent().get_parent()

func _vector_to_id(vec):
	return int(str(vec.y) + str(vec.x))
	
func _get_prev_instruction():
	return _instructions[_instructions.size()-1] if _instructions.size() >= 1 else null
