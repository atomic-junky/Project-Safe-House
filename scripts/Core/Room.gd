extends Node
class_name Room

var id: String = UUID.v4()
var max_size: int = 3
var size: int = 1 :
	get:
		return len(positions)
var destroyable: bool = true
var room_level: int = 0
var positions: Array[Vector2]

var mesh: Dictionary :
	get = _get_mesh

var room_node: Node3D
var dwellers: Array = []
var working_spots: WorkingPool = WorkingPool.new()

var region
var _matrix: Matrix

var position: Vector3 :
	get:
		return room_node.position

var global_position: Vector3 :
	get:
		return room_node.global_position


func _init() -> void:
	call("_constructor")

	if self is EmptyLocation:
		return
	Logger.info("Room(" + id + ") created")

# Fonction pouvant être écrasée appelée à l'initialisation
func _constructor() -> void:
	pass

func _get_mesh():
	return self.meshes[size]

func _register_dweller(dweller: Dweller) -> bool:
	if not dwellers.has(dweller.id):
		dwellers.append(dweller.id)
	
	return working_spots._assign_dweller(size, dweller)

func _forget_dweller(dweller: Dweller) -> void:
	if dwellers.has(dweller.id):
		dwellers.erase(dweller.id)
	
	if working_spots.has_dweller(size, dweller):
		working_spots._deassign_dweller(size, dweller)

func has_dweller(dweller: Dweller) -> bool:
	return working_spots.has_dweller(size, dweller)

func is_full() -> bool:
	return working_spots.is_full(size)

func get_work_position(dweller: Dweller):
	return working_spots.get_position(size, dweller)

func _sort_postions(a: Vector2, b: Vector2) -> bool:
	if a.x < b.x:
		return true
	return false

func get_navigation_region() -> NavigationRegion3D:
	return room_node.get_node_or_null("NavigationRegion3D")

func get_first_position():
	var result = positions.duplicate()
	result.sort_custom(_sort_postions)
	
	return result[0]

static func get_room_mesh(_size):
	return 0

func destroy():
	_matrix.remove_room(self)

func upgrade():
	room_level += 1

func can_be_destroy():
	if !destroyable:
		return false
	
	var astar: AStar2D = _matrix._build_astar_path()
	var end_index = Matrix._vector_to_astar_id(_matrix.get_start_room().positions[0])
	for pos in positions:
		var s_index = Matrix._vector_to_astar_id(pos)
		astar.remove_point(s_index)

	var neighbors = [
		_matrix.get_room_at(positions[0].x-1, positions[0].y),
		_matrix.get_room_at(positions.back().x+1, positions.back().y)
	]
	if self is ElevatorShaft:
		neighbors.append_array([
			_matrix.get_room_at(positions[0].x, positions[0].y-1),
			_matrix.get_room_at(positions.back().x, positions.back().y+1)
		])

	for neighbor in neighbors:
		if neighbor == null or neighbor is EmptyLocation:
			continue

		var start_index = Matrix._vector_to_astar_id(neighbor.positions[0])
		if astar.get_point_path(start_index, end_index).size() <= 0:
			return false
	return true