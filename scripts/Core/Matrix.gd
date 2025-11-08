class_name Matrix

signal room_removed

const RoomEntity := preload("res://scripts/entities/RoomEntity.gd")

var size: Vector2 = Vector2.ZERO
var matrix: Array[Array]


func _init(width: int, height: int) -> void:
	size = Vector2(width, height)

	# Create the room matrix
	for y in range(height):
		matrix.append([])
		for x in range(width):
			matrix[y].append(null)


func add_room(room: Variant, positions: Array[Vector2]) -> void:
	if room == null:
		return

	_bind_room_to_matrix(room)

	var placeholders: Array = []

	for _pos: Vector2 in positions:
		if _pos.x < 0 or _pos.x >= size.x or _pos.y < 0 or _pos.y >= size.y:
			return
		var current = matrix[_pos.y][_pos.x]
		if current != null:
			if current is EmptyLocation:
				placeholders.append(current)
				continue
			return

	for placeholder in placeholders:
		if placeholder is Node:
			(placeholder as Node).queue_free()

	for _pos: Vector2 in positions:
		matrix[_pos.y][_pos.x] = room

	_assign_positions(room, positions)

	if room is AbstractRoom:
		for _pos: Vector2 in positions:
			var left_neighbour: Variant = get_room_at(int(_pos.x - 1), int(_pos.y))
			if _can_merge(left_neighbour, room):
				room = _merge_rooms(left_neighbour, room)

			var right_neighbour: Variant = get_room_at(int(_pos.x + 1), int(_pos.y))
			if _can_merge(right_neighbour, room):
				room = _merge_rooms(right_neighbour, room)


func remove_room(room: Variant) -> void:
	if room == null:
		return

	var room_positions: Array[Vector2] = _get_positions(room)
	for _pos: Vector2 in room_positions:
		matrix[int(_pos.y)][int(_pos.x)] = null

	if room is Node:
		(room as Node).queue_free()
	room_removed.emit()


func _merge_rooms(base_room: AbstractRoom, new_room: AbstractRoom) -> AbstractRoom:
	base_room.positions.append_array(new_room.positions)
	FSLogger.info("Room(" + new_room.id + ") merged with Room(" + base_room.id + ")")
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


func get_room_at(x: int, y: int) -> Variant:
	return matrix[y][x] if _is_room_at(x, y) else null


func get_room_at_first_position(x: int, y: int) -> Variant:
	var room: Variant = get_room_at(x, y)
	if room == null:
		return

	var r_positions: Array[Vector2] = _get_positions(room)
	if r_positions.is_empty():
		return null
	r_positions.sort_custom(_sort_postions)
	return room if Vector2(x, y) == r_positions[0] else null


func _build_astar_path() -> AStar2D:
	var astar: AStar2D = AStar2D.new()

	for y in range(size.y):
		for x in range(size.x):
			if not _is_room_at(x, y):
				continue

			var point_id: int = Matrix._vector_to_astar_id(Vector2i(x, y))
			astar.add_point(point_id, Vector2i(x, y))

	for y in range(size.y):
		for x in range(size.x):
			var room: Variant = get_room_at(x, y)
			if room == null or room is EmptyLocation:
				continue

			var point_id: int = Matrix._vector_to_astar_id(Vector2i(x, y))
			var left_id: int = -1
			var right_id: int = -1
			if _is_room_at(x - 1, y):
				left_id = Matrix._vector_to_astar_id(Vector2i(x - 1, y))
			if _is_room_at(x + 1, y):
				right_id = Matrix._vector_to_astar_id(Vector2i(x + 1, y))

			if left_id != -1:
				astar.connect_points(point_id, left_id)
			if right_id != -1:
				astar.connect_points(point_id, right_id)

			if room is ElevatorShaft:
				var top_id: int = -1
				var bottom_id: int = -1
				if get_room_at(x, y - 1) is ElevatorShaft:
					top_id = Matrix._vector_to_astar_id(Vector2i(x, y - 1))
				if get_room_at(x, y + 1) is ElevatorShaft:
					bottom_id = Matrix._vector_to_astar_id(Vector2i(x, y + 1))

				if top_id != -1:
					astar.connect_points(point_id, top_id)
				if bottom_id != -1:
					astar.connect_points(point_id, bottom_id)

	return astar


static func _vector_to_astar_id(vec: Vector2i) -> int:
	return int(str(vec.y) + str(vec.x))


func _vector_to_center_room_astar_id(vec: Vector2i) -> int:
	var room: Variant = get_room_at(vec.x, vec.y)
	var r_positions: Array[Vector2] = _get_positions(room)
	if r_positions.is_empty():
		return -1
	r_positions.sort_custom(_sort_postions)
	var count: int = r_positions.size()
	var index: int = count >> 1
	if count % 2 == 0:
		index = max(index - 1, 0)
	var center: Vector2 = r_positions[index]
	return Matrix._vector_to_astar_id(Vector2i(int(center.x), int(center.y)))


func _vector_to_center_room_position(vec: Vector2i) -> Vector2:
	var room: Variant = get_room_at(vec.x, vec.y)
	var r_positions: Array[Vector2] = _get_positions(room)
	if r_positions.is_empty():
		return Vector2.ZERO
	r_positions.sort_custom(_sort_postions)
	var count: int = r_positions.size()
	if count % 2 != 0:
		var modifier: Vector2 = (r_positions.back() - r_positions[0]) / 2.0
		modifier.x += 0.5
		return r_positions[0] + modifier
	var midpoint_index: int = count >> 1
	return r_positions[midpoint_index]


func get_all_rooms() -> Array:
	var result: Array = []
	for y in matrix:
		result.append_array(y)
	return result


func _bind_room_to_matrix(room: Variant) -> void:
	if room is AbstractRoom:
		room._matrix = self
	elif room is RoomEntity:
		(room as RoomEntity).set_matrix(self)


func _assign_positions(room: Variant, positions: Array[Vector2]) -> void:
	if room is AbstractRoom:
		room.positions = positions.duplicate()
	elif room is RoomEntity:
		(room as RoomEntity).set_positions(positions)


func _get_positions(room: Variant) -> Array[Vector2]:
	if room is RoomEntity:
		return (room as RoomEntity).positions.duplicate()
	if room is AbstractRoom:
		return room.positions.duplicate()
	return []


func _can_merge(base_room: Variant, new_room: Variant) -> bool:
	if base_room == null or new_room == null:
		return false
	if not (base_room is AbstractRoom and new_room is AbstractRoom):
		return false
	var base := base_room as AbstractRoom
	var candidate := new_room as AbstractRoom
	return base.get_script() == candidate.get_script() and base.size < candidate.max_size


func get_start_room() -> Variant:
	return get_room_at(1, 0)
