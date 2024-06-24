extends Node3D
class_name ElevatorPlatform

@export var machine: StateMachine

const MAX_SPEED: float = 1.0

@onready var _slot_markers = $SlotMarkers
@onready var t_departure: Timer = get_node("Timers/tDeparture")

var network: Array = []

var _current_elevator: Room
var _target_elevator: Room
var _requests: Array = []

var spots_pool: WorkingPool
var accept_dweller: bool = true

func _ready():
	var working_pool_param = WorkingPoolParameters.new()
	working_pool_param._from_markers(1, _slot_markers)

	spots_pool = WorkingPool.new(working_pool_param)

func _assign_dweller(dweller: Dweller):
	spots_pool._assign_dweller(1, dweller)

func _deassign_dweller(dweller: Dweller):
	spots_pool._deassign_dweller(1, dweller)

func _transfer_dwellers(dwellers: Array):
	for dweller in dwellers:
		spots_pool._assign_dweller(1, dweller)

func _process(_delta):
	for shaft in network:
		if not is_instance_valid(shaft):
			return

		if shaft.position.y == position.y:
			_current_elevator = shaft

func get_dweller_pos(dweller: Dweller):
	return global_position + spots_pool.get_position(1, dweller)

func request(elevator: ElevatorShaft):
	if elevator == _current_elevator or elevator in _requests:
		return
	_requests.append(elevator)

func _can_go() -> bool:
	if len(_requests) <= 0:
		return false

	# Check if all dwellers are in place
	for spot in spots_pool.get_all_taken(1):
		var dweller = spot.dweller
		if !dweller.machine.state is EIdlePlatformState:
			return false

	return true

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
func is_empty():
	return spots_pool.is_empty(1)

func _on_t_departure_timeout():
	_target_elevator = _get_next_floor()

func _move_to_floor(delta: float, pos_y: float):
	global_position.y = move_toward(global_position.y, pos_y, delta * MAX_SPEED)

	for spot in spots_pool.get_all_taken(1):
		spot.dweller.global_position = get_dweller_pos(spot.dweller)

func is_idle() -> bool:
	return machine.state is EPIdleState