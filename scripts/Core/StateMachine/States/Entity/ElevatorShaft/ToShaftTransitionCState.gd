@tool
class_name EPlatformToShaft extends Transition


const TRAVEL_SPEED = 1.5

var current_elevator: ElevatorShaft
var _target_pos: Array[Vector3]


func _is_valid(actor: Node) -> bool:
	var platform = actor.map_path.prev_room._platform
	return platform._current_elevator == actor.map_path.get_current_room() and not actor.map_path.get_next_room() is ElevatorShaft


func _enter(actor: Node) -> void:
	current_elevator = actor.map_path.get_current_room()

	await current_elevator.open

	_target_pos.append(current_elevator._get_second_transfer_position())
	_target_pos.append(current_elevator._get_first_transfer_position())


func _update(delta: float, actor: Node) -> void:
	if !current_elevator.is_open:
		return

	if _target_pos[0] == actor.global_position:
		_target_pos.pop_front()

		if len(_target_pos) <= 0:
			completed.emit()
			return

	actor.move_to_position(delta, _target_pos[0], TRAVEL_SPEED)
	
