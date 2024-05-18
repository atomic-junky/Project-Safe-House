class_name EToShaftTransitionCState
extends CompositeState


const TRAVEL_SPEED = 1.5

var current_elevator: ElevatorShaft
var _target_pos: Array[Vector3]


func _enter(_msg={}) -> void:
    current_elevator = node.map_path.get_current_room()

    await current_elevator.open

    _target_pos.append(current_elevator._get_second_transfer_position())
    _target_pos.append(current_elevator._get_first_transfer_position())


func _do(delta: float) -> void:
    if !current_elevator.is_open:
        return

    if _target_pos[0] == node.global_position:
        _target_pos.pop_front()

        if len(_target_pos) <= 0:
            completed.emit()
            return

    node.move_to_position(delta, _target_pos[0], TRAVEL_SPEED)
    
