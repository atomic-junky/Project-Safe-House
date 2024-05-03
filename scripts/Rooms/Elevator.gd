extends Room

class_name Elevator


var _platform: ElevatorPlaform
var is_open = false


var meshes = {
	1: MeshLink._meshes.ELEVATOR_MIDDLE
}


func _constructor():
	max_size = 1

	for key in meshes:
		var el = meshes[key]

		var working_pool_param = WorkingPoolParameters.new()
		working_pool_param.append_positions(
			1, MeshLink.get_spots(el.name)
		)

		working_spots = WorkingPool.new(working_pool_param)

	set_process(true)


func _process(_delta):
	if _platform._current_elevator == self and not is_open:
		_get_animation_player().play("open_door")
		is_open = true
	
	if is_open and _platform._current_elevator != self:
		await get_tree().create_timer(1.0).timeout
		_get_animation_player().play("close_door")
		is_open = false


func _get_animation_player() -> AnimationPlayer:
	return room_node.get_node("AnimationPlayer")


func wait_for_elevator(dweller: Dweller):
	working_spots._assign_dweller(size, dweller)
	var position = working_spots.get_position(size, dweller)
	
	dweller._target_pos = self.room_node.global_position + position
	
	ask_for_elevator(self)


func transfer_dweller_to_platform(dweller: Dweller):
	working_spots._deassign_dweller(size, dweller)
	_platform._assign_dweller(dweller)


func ask_for_elevator(elevator: Elevator):
	_platform.request(elevator)


func _get_first_transfer_position() -> Vector3:
	return room_node.global_position + room_node.get_node("TransferMarkers/m01").position


func _get_second_transfer_position() -> Vector3:
	return room_node.global_position + room_node.get_node("TransferMarkers/m02").position


func is_empty():
	return working_spots.is_empty(size)