extends Node3D
class_name ElevatorPlaform


const MAX_SPEED: float = 1.0

@onready var _slot_markers = $SlotMarkers

var network: Array = []

var _current_elevator: Room
var _target_elevator: Room
var _requests: Array = []

var spots_pool: WorkingPool


func _ready():
	var working_pool_param = WorkingPoolParameters.new()
	working_pool_param._from_markers(1, _slot_markers)

	spots_pool = WorkingPool.new(working_pool_param)


func _assign_dweller(dweller: Dweller):
	spots_pool._assign_dweller(1, dweller)
	dweller._target_pos = global_position + spots_pool.get_position(1, dweller)


func _transfer_dwellers(dwellers: Array):
	for dweller in dwellers:
		spots_pool._assign_dweller(1, dweller)


func _process(delta):
	_current_elevator = null
	for elevator in network:
		if elevator.room_node.global_position.y == global_position.y:
			_current_elevator = elevator
			_requests.erase(_current_elevator)

	if _target_elevator == null and _current_elevator != null and not _requests.is_empty():
		_target_elevator = _get_next_floor()

	if _target_elevator != null and (_current_elevator == null or _current_elevator != _target_elevator):
		if _current_elevator and _requests.is_empty():
		# if _current_elevator and not (_current_elevator.is_empty() or is_full()):
			return

		var _target_pos = _target_elevator.room_node.global_position
		global_position.y = move_toward(global_position.y, _target_pos.y, delta * MAX_SPEED)
		
		for spot in spots_pool.get_all_taken(1):
			spot.dweller._target_pos = global_position + spots_pool.get_position(1, spot.dweller)
	elif _current_elevator == _target_elevator:
		_target_elevator = null
		for spot in spots_pool.get_all_taken(1):
			await get_tree().create_timer(1.0).timeout
			spot.dweller._is_on_elevator_platform = false
			spots_pool._deassign_dweller(1, spot.dweller)


func request(elevator: Elevator):
	_requests.append(elevator)


func _sort_high_floors(a, b) -> bool:
	return a.positions[0].y < b.positions[0].y
func _sort_low_floors(a, b) -> bool:
	return a.positions[0].y > b.positions[0].y


func _get_next_floor():
	var high_floors = _requests.duplicate()
	high_floors.sort_custom(_sort_high_floors)
	high_floors.filter(func(f): return f.positions[0].y < _current_elevator.positions[0].y)
	
	var low_floors = _requests.duplicate()
	low_floors.sort_custom(_sort_low_floors)
	high_floors.filter(func(f): return f.positions[0].y > _current_elevator.positions[0].y)

	var ordered_requests = high_floors
	ordered_requests.append_array(low_floors)

	return ordered_requests[0]


func is_full():
	return spots_pool.is_full(1)