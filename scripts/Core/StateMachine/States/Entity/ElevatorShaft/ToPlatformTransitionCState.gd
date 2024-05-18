class_name EToPlatformTransitionCState
extends CompositeState


const TRAVEL_SPEED = 1.5

@export var elevator_platform_state: State

var current_elevator: ElevatorShaft
var _target_pos: Array[Vector3]


func _enter(_msg={}) -> void:
    current_elevator = node.map_path.prev_room

    _target_pos.append(current_elevator._get_first_transfer_position())
    _target_pos.append(current_elevator._get_second_transfer_position())


func _do(delta: float) -> void:
    if _target_pos[0] == node.global_position:
        _target_pos.pop_front()

        if len(_target_pos) <= 0:
            completed.emit()
            return

    node.move_to_position(delta, _target_pos[0], TRAVEL_SPEED)
    
