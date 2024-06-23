class_name Matrix


signal room_removed

var size: Vector2 = Vector2.ZERO
var matrix: Array[Array]


func _init(width: int, height: int) -> void:
	size = Vector2(width, height)
	
	# Create the room matrix
	for y in range(height):
		matrix.append([])
		for x in range(width):
			matrix[y].append(null)


func add_room(room: Room, positions: Array[Vector2]) -> void:
	room._matrix = self
	for _pos in positions:
		# Checking limits
		if _pos.x < 0 or _pos.x >= size.x or _pos.y < 0 or _pos.y >= size.y:
			return
		
		# Checking free space
		if matrix[_pos.y][_pos.x] != null:
			return
	
	for _pos in positions:
		# Adding the room to the matrix at all room positions
		matrix[_pos.y][_pos.x] = room
		room.positions = positions
		
		# Merge with neighbours if they are of the same type
		var left_neighbour = get_room_at(_pos.x-1, _pos.y)
		if left_neighbour != null and left_neighbour.get_script() == room.get_script() and left_neighbour.size < room.max_size:
			room = _merge_rooms(left_neighbour, room)
		
		var right_neighbour = get_room_at(_pos.x+1, _pos.y)
		if right_neighbour != null and right_neighbour.get_script() == room.get_script() and right_neighbour.size < room.max_size:
			room = _merge_rooms(right_neighbour, room)


func remove_room(room: Room) -> void:
	for _pos in room.positions:
		# Delete room at all room positions on the matrix
		matrix[_pos.y][_pos.x] = null
		
	room.queue_free()
	room_removed.emit()


func _merge_rooms(base_room: Room, new_room: Room) -> Room:
	base_room.positions.append_array(new_room.positions)
	Logger.info("Room(" + new_room.id + ") merged with Room(" + base_room.id + ")")
	new_room.free()
	
	for pos in base_room.positions:
		matrix[pos.y][pos.x] = base_room
	
	return base_room


func _is_room_at(x: int, y: int) -> bool:
	return x >= 0 and x < size.x and y >= 0 and y < size.y and matrix[y][x] != null


func _sort_postions(a: Vector2, b: Vector2) -> bool:
	if a.x < b.x:
		return true
	return false


func get_room_at(x: int, y: int) -> Room:
	return matrix[y][x] if _is_room_at(x, y) else null


func get_room_at_first_position(x: int, y: int):
	var room: Room = get_room_at(x, y)
	if room == null:
		return
	
	var r_positions = room.positions
	r_positions.sort_custom(_sort_postions)
	return room if Vector2(x, y) == r_positions[0] else null


func _build_astar_path() -> AStar2D:
	var astar = AStar2D.new()
	
	for y in range(size.y):
		for x in range(size.x):
			if not _is_room_at(x, y):
				continue
			
			var point_id = Matrix._vector_to_astar_id(Vector2i(x, y))
			astar.add_point(point_id, Vector2i(x, y))
	
	for y in range(size.y):
		for x in range(size.x):
			var room = get_room_at(x, y)
			if room == null or room is EmptyLocation:
				continue
			
			var point_id = Matrix._vector_to_astar_id(Vector2i(x, y))
			var left_id = Matrix._vector_to_astar_id(Vector2i(x-1, y)) if _is_room_at(x-1, y) else null
			var right_id = Matrix._vector_to_astar_id(Vector2i(x+1, y)) if _is_room_at(x+1, y) else null
			
			if left_id != null:
				astar.connect_points(point_id, left_id)
			if right_id != null:
				astar.connect_points(point_id, right_id)
				
			if room is ElevatorShaft:
				var top_id = Matrix._vector_to_astar_id(Vector2i(x, y-1)) if get_room_at(x, y-1) is ElevatorShaft else null
				var bottom_id = Matrix._vector_to_astar_id(Vector2i(x, y+1)) if get_room_at(x, y+1) is ElevatorShaft else null
				
				if top_id != null:
					astar.connect_points(point_id, top_id)
				if bottom_id != null:
					astar.connect_points(point_id, bottom_id)
	
	return astar


static func _vector_to_astar_id(vec):
	return int(str(vec.y) + str(vec.x))


func _vector_to_center_room_astar_id(vec):
	var room = get_room_at(vec.x, vec.y)
	var r_positions = room.positions
	r_positions.sort_custom(_sort_postions)
	
	if len(r_positions) % 2 == 0:
		return Matrix._vector_to_astar_id(r_positions[len(r_positions)/2-1])
		
	return Matrix._vector_to_astar_id(r_positions[len(r_positions)/2-0.5])


func _vector_to_center_room_position(vec):
	var room = get_room_at(vec.x, vec.y)
	var r_positions = room.positions
	r_positions.sort_custom(_sort_postions)
	
	if len(r_positions) % 2 != 0:
		var modifier = (r_positions.back() - r_positions[0])/2
		modifier.x += 0.5

		return r_positions[0] + modifier
		
	return r_positions[(len(r_positions))/2]


func get_all_rooms():
	var result = []
	for y in matrix:
		result.append_array(y)
	return result


func get_start_room():
	return get_room_at(1, 0)
