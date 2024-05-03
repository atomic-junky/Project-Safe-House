class_name MapPath


var _astar: AStar2D
var _path: Array

var _matrix
var _map_height: int
var _cell_size: Vector3

var is_cleared: bool = false
var prev_room: Room


func _init(astar: AStar2D, start_index: int, end_index: int, cell_size: Vector3, matrix: Matrix):
	_astar = astar
	_path = astar.get_id_path(start_index, end_index)

	_matrix = matrix
	_map_height = matrix.size.y
	_cell_size = cell_size

	_clean_path()


func _clean_path():
	# Remove points that refer to the same room
	var _room_cache = []

	for p_index in _path:
		var p_pos = _astar.get_point_position(p_index)
		var room = _matrix.get_room_at(p_pos.x, p_pos.y)
		
		if room.id in _room_cache:
			_path.erase(p_index)
			continue
		
		_room_cache.append(room.id)

	# Remove in between elevators
	for i in len(_path)-1:
		if i <= 0:
			continue

		var p_pos = _astar.get_point_position(_path[i])
		var p_room = _matrix.get_room_at(p_pos.x, p_pos.y)

		var prev_p_pos = _astar.get_point_position(_path[i-1])
		var prev_p_room = _matrix.get_room_at(prev_p_pos.x, prev_p_pos.y)

		if prev_p_room is Elevator and p_room is Elevator:
			if prev_p_pos.x == p_pos.x:
				_path.erase(_path[i])


func pop_next_target_pos() -> Vector3:
	assert(len(_path) > 0)

	var p_index = _path[0]
	var p_pos = _astar.get_point_position(p_index)

	var room_pos = _matrix._vector_to_center_room_position(p_pos)

	var z = room_pos.x * _cell_size.z * -1
	var y = (_map_height - room_pos.y) * _cell_size.y - 0.905 - 2

	var p_global_position = Vector3(-1, y, z)

	prev_room = get_next_room()

	_path.remove_at(0)

	if len(_path) <= 0:
		is_cleared = true

	return p_global_position


func get_next_room():
	if len(_path) <= 0:
		return null

	var p_index = _path[0]
	var p_pos = _astar.get_point_position(p_index)

	return _matrix.get_room_at(p_pos.x, p_pos.y)