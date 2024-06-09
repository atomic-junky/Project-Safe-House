extends Room

class_name ElevatorShaft

signal open
signal close

var _platform: ElevatorPlatform
var is_open = false

var meshes = {
	1: MeshLink._meshes.ELEVATOR_MIDDLE
}

var room_name: String = "Elevator Shaft"

func _constructor():
	max_size = 1

	for key in meshes:
		var el = meshes[key]

		var working_pool_param = WorkingPoolParameters.new()
		working_pool_param.append_positions(
			key, MeshLink.get_spots(el.name)
		)

		working_spots = WorkingPool.new(working_pool_param)

func _process(_delta):
	if is_open and !working_spots.is_empty(size) and _platform._current_elevator == self and _platform.accept_dweller:
		transfer_dwellers_to_platform()
	
	if !is_open and !working_spots.is_empty(size):
		ask_for_elevator(self)
	
	if _get_animation_player().is_playing():
		return

	var p_current_elevator = _platform._current_elevator

	if is_open and (p_current_elevator != self or _platform._can_go()):
		_get_animation_player().play("close_door")
		await _get_animation_player().animation_finished
		is_open = false
		close.emit()
	elif p_current_elevator == self and !is_open and _platform.is_idle() and _platform.accept_dweller:
		_get_animation_player().play("open_door")
		await _get_animation_player().animation_finished
		is_open = true
		open.emit()

func _get_animation_player() -> AnimationPlayer:
	return room_node.get_node("AnimationPlayer")

func wait_for_elevator(dweller: Dweller):
	var err = working_spots._assign_dweller(size, dweller)
	var s_position = working_spots.get_position(size, dweller)

	if !err and !s_position:
		Logger.error("Can't assign the dweller to the elevator shaft")

	return self.room_node.global_position + s_position

func transfer_dwellers_to_platform():
	for spot in working_spots.get_all_taken(size):
		if _platform.is_full():
			return

		var dweller = spot.dweller

		_transfer_dweller_to_platform(dweller)

func _transfer_dweller_to_platform(dweller: Dweller):
	working_spots._deassign_dweller(size, dweller)
	_platform._assign_dweller(dweller)

	dweller.elevator_transfer.emit()

func ask_for_elevator(elevator: ElevatorShaft):
	_platform.request(elevator)

func _get_first_transfer_position() -> Vector3:
	return room_node.global_position + room_node.get_node("TransferMarkers/m01").position

func _get_second_transfer_position() -> Vector3:
	return room_node.global_position + room_node.get_node("TransferMarkers/m02").position

func is_empty():
	return working_spots.is_empty(size)