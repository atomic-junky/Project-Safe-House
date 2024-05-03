extends Entity

class_name Dweller


const MAX_SPEED = 1.5
var id: String = UUID.v4()

var assigned_room = null
var is_traveling = false

var map_path: MapPath
var _target_pos

var _waiting_on_elevator: bool = false
var _is_on_elevator_platform: bool = false
var _elevator_transfer_process: int = 0

var matrix_position:
	get:
		var shelter_map = get_tree().current_scene.find_child("SceneMap")
		var z = floori((position.z/ shelter_map.cell_size.z)*-1) # x axis
		var y = roundi((position.y)/ shelter_map.cell_size.y) # y axis
		return Vector2i(z, y)


func _ready():
	position.y = 47.095
	

func _process(delta):
	_travel_process(delta)


func _travel_process(delta):
	# TODO: Simplify this mess (the elevator logic part)
	if not map_path or (map_path.is_cleared and _target_pos == global_position):
		return

	var _prev_room	= map_path.prev_room
	var _next_room	= map_path.get_next_room()
	if _prev_room is Elevator and _next_room is Elevator and (_target_pos == global_position or _prev_room.is_open) and not _waiting_on_elevator:
		_waiting_on_elevator = true
	
	if _waiting_on_elevator:
		return _elevator_process(delta)

	if _target_pos == null or _target_pos == global_position:
		if _next_room is Elevator:
			# Get the accurate position if the next room is an elevator
			_next_room.wait_for_elevator(self)
			map_path.pop_next_target_pos()
		else:
			_target_pos = map_path.pop_next_target_pos()
			

	_move_process(delta)


func _elevator_process(delta):
	var elevator = map_path.prev_room if map_path.prev_room != null else assigned_room

	if not elevator.is_open and _elevator_transfer_process == 0:
		return

	# Exception if the door is already open
	if elevator.is_open and _elevator_transfer_process == 0:
		_elevator_transfer_process += 1
		_target_pos = elevator._get_first_transfer_position()

	if _target_pos == global_position and not _is_on_elevator_platform:
		_elevator_transfer_process += 1

		match _elevator_transfer_process:
			1:
				_target_pos = elevator._get_first_transfer_position()
			2:
				_target_pos = elevator._get_second_transfer_position()
			3:
				elevator.transfer_dweller_to_platform(self)
				elevator.ask_for_elevator(map_path.get_next_room())
				_is_on_elevator_platform = true
			4:
				_target_pos = map_path.pop_next_target_pos()
			5:
				_waiting_on_elevator = false
				_elevator_transfer_process = 0

	_move_process(delta)



func _move_process(delta):
	global_position.y = move_toward(global_position.y, _target_pos.y, delta * MAX_SPEED)
	global_position.z = move_toward(global_position.z, _target_pos.z, delta * MAX_SPEED)
	global_position.x = move_toward(global_position.x, _target_pos.x, delta * MAX_SPEED)



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