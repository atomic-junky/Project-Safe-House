@tool
class_name EShaftToPlatformTransition extends Transition


const TRAVEL_SPEED = 1.5

var elevator: ElevatorShaft
var target_pos: Array[Vector3]


func _load(actor: Node) -> void:
	register_signal(actor.elevator_transfer)


func _enter(actor: Node) -> void:
	elevator = actor.map_path.prev_room

	target_pos.append(elevator._get_first_transfer_position())
	target_pos.append(elevator._get_second_transfer_position())
	target_pos.append(elevator._platform.get_dweller_pos(actor))


func _update(delta: float, actor: Node) -> void:
	if target_pos[0] == actor.global_position:
		target_pos.pop_front()

		if len(target_pos) <= 0:
			completed.emit()
			return

	actor.move_to_position(delta, target_pos[0], TRAVEL_SPEED)
	
