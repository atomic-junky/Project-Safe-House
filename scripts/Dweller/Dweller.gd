extends Node3D

const MAX_SPEED = 3
var target_positions = []
var instructions = []

var assigned_room = null # A reference to the room
var is_traveling = false

var is_waiting_outside = true

var matrix_position:
	get:
		var grid_map = get_tree().current_scene.find_child("GridMap")
		var z = roundi(position.z/ grid_map.cell_size.z) * -1
		var y = roundi((position.y)/ grid_map.cell_size.y)
		return Vector2i(z, y)

func _ready():
	position.y = 47.095
	
func _process(delta):
	is_waiting_outside = true if assigned_room == null else false
	
	if instructions:
		is_traveling = true
		
		var sub_target_position = target_positions[0] if target_positions else null
		var instruction = instructions[0]
		var vel = global_position.z * MAX_SPEED
		
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
		
		if target_positions and instruction == Instructions.MOVE_ON_FLOOR and \
		global_position.y == sub_target_position.y and \
		global_position.z == sub_target_position.z:
			target_positions.remove_at(0)
			instructions.remove_at(0)
	else:
		target_positions.clear()
		instructions.clear()
		is_traveling = false

func get_main_parent():
	return get_parent().get_parent().get_parent()

func _input(event):
	if Global.interface_mode:
		return
		
	return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var camera = get_tree().current_scene.find_child("Camera")
		if not camera:
			return
		
		var ray = camera.screen_point_to_ray()
		if ray.has("collider") and ray.collider == $Body:
			print("collide")
		
		var grid_map = get_tree().current_scene.find_child("GridMap")
		var parent = get_parent_node_3d()
		if not grid_map or not parent:
			return
		
		var mouse_3d = camera.screen_point_to_ray()
		if not mouse_3d.has("position"):
			return
		
		target_position_calculator(mouse_3d.position)

func target_position_calculator(pos):
	var grid_map = get_tree().current_scene.find_child("GridMap")
	
	var z = roundi(pos.z/ grid_map.cell_size.z) * -1
	var y = roundi((pos.y)/ grid_map.cell_size.y)
	path_to_room(z, y)

func path_to_room(z, y):
	var parent = get_main_parent()
	var matrix = parent.matrix
	var max_height = parent.max_height
	var target_room = matrix[max_height - y][z].get_ref()
	
	if target_room.type < RoomList.ELEVATOR:
		return
	assigned_room = matrix[max_height - y][z]
		
	var max_width = matrix[0].size() - 1
	
	var prev_room = matrix[max_height - y][z-1].get_ref() if z > 0 else null
	var next_room = matrix[max_height - y][z+1].get_ref() if z < max_width else null
	
	var z_modifer = 0
	# Get room position
	# [] [x] []
	if prev_room and prev_room.id == target_room.id and next_room and next_room.id == target_room.id:
		pass
	# [x] []
	elif (not prev_room or prev_room.id != target_room.id) and next_room and next_room.id == target_room.id:
		# [x] [] []
		if z+1 < max_width and matrix[max_height - y][z+2].get_ref().id == target_room.id:
			z+=1
		else:
			z_modifer = 0.5
	# [] [x]
	elif (not next_room or next_room.id != target_room.id) and prev_room and prev_room.id == target_room.id:
		# [] [] [x]
		if z-1 > 0 and matrix[max_height - y][z-2].get_ref().id == target_room.id:
			z-=1
		else:
			z_modifer = -0.5
		
	if instructions and instructions[0] == Instructions.MOVE_ON_FLOOR:
		target_positions.clear()
		instructions.clear()

	var start = Vector2i(matrix_position.x, max_height - matrix_position.y)
	var end = Vector2i(z, max_height - y)

	best_path(start, end, z_modifer)

# ================ BEST PATH ================
# Calcul the best path to go to a room using astar
# 
# => Fill an array of instructions (instructions)
# => Fill an array of moving points (target_postions)
# 
func best_path(start, end, z_modifer):
	var parent = get_main_parent()
	var grid_map = get_tree().current_scene.find_child("GridMap")
	var matrix = parent.matrix
	var max_height = parent.max_height
	# Copy the matrix in a new array
	# -1 => dirt; 0 => room; 1 => elevator
	
	var astar = AStar2D.new()
	var start_index = 0
	var end_index = 0
	
	# ASTAR PATH
	for y in matrix.size():
		for x in matrix[y].size():
			var room = matrix[y][x]
			
			var id = vector_to_id(Vector2i(x, y))
			
			if Vector2i(x, y) == start: start_index = id
			if Vector2i(x, y) == end: end_index = id
			
			var prev_point = astar.get_point_position(id-1) if astar.has_point(id-1) else null
			match room.get_ref().type:
				-2, -1, 0, 1:
					continue
				2:
					astar.add_point(id, Vector2i(x, y), 1.0)
					# If prev point is a room
					if prev_point and prev_point.y == y and prev_point.x+1 == x:
						astar.connect_points(id-1, id)
						
					var top_room = matrix[y-1][x].get_ref() if y > 0 else null
					# If elevator on top
					if top_room and top_room.type == RoomList.ELEVATOR:
						astar.connect_points(vector_to_id(Vector2i(x, y-1)), id)
					continue
				_:
					astar.add_point(id, Vector2i(x, y), 0.0)
					print(prev_point)
					# If prev point is a room
					if prev_point and prev_point.y == y and prev_point.x+1 == x:
						astar.connect_points(id-1, id)
					continue
	
	if is_waiting_outside:
		var new_parent = get_main_parent()
		get_parent().remove_child(self)
		new_parent.dc_assigned.add_child(self)
		astar.add_point(0, Vector2i.ZERO, 0.0)
		astar.connect_points(0, 1)
	
	var path = astar.get_id_path(start_index, end_index)
	
	# INSTRUCTIONS from the astar path
	for index in path.size():
		var point_position = astar.get_point_position(path[index])
		var prev_position = astar.get_point_position(path[index - 1]) if index - 1 >= 0 else null
		var next_position = astar.get_point_position(path[index + 1]) if index + 1 < path.size() else null
		
		var current_room = matrix[point_position.y][point_position.x].get_ref()
		var next_room = matrix[next_position.y][next_position.x].get_ref() if next_position else null
		var prev_room = matrix[prev_position.y][prev_position.x].get_ref() if prev_position else null
		
		var first_index_condition = index != 0 or path.size() <= 1
		
		var prev_instruction = get_prev_instruction()
		
		if current_room.type == RoomList.ELEVATOR:
			if prev_room and prev_position.x == point_position.x and prev_position.y != point_position.y:
				instructions.append(Instructions.EXIT_ELEVATOR)
				print("[DEBUG] Exit elevator (1)")
			elif not next_room:
				instructions.append(Instructions.EXIT_ELEVATOR)
				print("[DEBUG] Exit elevator (2)")
			elif next_room and next_room.type == RoomList.ELEVATOR:
				if next_position.x == point_position.x and next_position.y != point_position.y:
					instructions.append(Instructions.ENTER_ELEVATOR)
					print("[DEBUG] Enter elevator (1)")
			elif not prev_room and next_room and next_room.type == RoomList.ELEVATOR:
				instructions.append(Instructions.ENTER_ELEVATOR)
				print("[DEBUG] Enter elevator (2)")
				
		
		if current_room.type == RoomList.ELEVATOR:
			if next_room and next_room.type == RoomList.ELEVATOR:
				if (next_room.type == RoomList.ELEVATOR and next_position.x != point_position.x and next_position.y == point_position.y):
					instructions.append(Instructions.MOVE_ON_FLOOR)
					print("[DEBUG] Move on floor (1)")
				elif next_position.y != point_position.y:
					instructions.append(Instructions.MOVE_ON_ELEVATOR)
					print("[DEBUG] Move on elevator")
			else:
				instructions.append(Instructions.MOVE_ON_FLOOR)
				print("[DEBUG] Move on floor (2)")
		elif next_room and next_position.y == next_position.y:
			instructions.append(Instructions.MOVE_ON_FLOOR)
			print("[DEBUG] Move on floor (3)")
		
		# Append the target position for each time
		if first_index_condition:
			var z = point_position.x * grid_map.cell_size.z * -1
			if next_position == null:
				z = (point_position.x+z_modifer) * grid_map.cell_size.z * -1
			var y = (max_height - point_position.y) * grid_map.cell_size.y - 0.905
			target_positions.append(Vector3(0, y, z))
		
		print("[DEBUG] => Continue")
	
	print("[DEBUG] ========== End of Instructions ==========")
	
	if is_waiting_outside:
		get_main_parent().dc_on_hold.update_positions()

func get_prev_instruction():
	return instructions[instructions.size()-1] if instructions.size() >= 1 else null


func vector_to_id(vec):
	return int(str(vec.y) + str(vec.x))


func _on_t_enter_elevator_timeout():
	global_position.x = -1
	instructions.remove_at(0)


func _on_t_exit_elevator_timeout():
	instructions.remove_at(0)
	global_position.x = 0


func _on_t_move_elevator_timeout():
	if target_positions:
		instructions.remove_at(0)
		global_position.y = target_positions[0].y
		target_positions.remove_at(0)
