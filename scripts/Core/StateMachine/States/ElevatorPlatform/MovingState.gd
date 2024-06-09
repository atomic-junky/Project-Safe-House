class_name EPMovingState
extends State


@export var idle_state: EPIdleState

var _target_floor: ElevatorShaft
var _target_y_pos: float
var _waiting: bool = false


func _enter(_msg={}) -> void:
    node.accept_dweller = false
    _waiting = true
    _target_floor = node._get_next_floor()
    _target_y_pos = _target_floor.global_position.y

    var elevator_shaft = node._current_elevator
    if elevator_shaft.is_open:
        await node._current_elevator.close
    _waiting = false


func _do(delta: float) -> void:
    if _waiting:
        return

    if node.global_position.y == _target_y_pos:
        parent.transition_to(idle_state)
        node._requests.erase(node._current_elevator)
        return
    
    node._move_to_floor(delta, _target_y_pos)