class_name EPMovingState
extends State


@export var idle_state: EPIdleState

var _target_floor: Elevator
var _target_y_pos: float


func _enter(_msg={}) -> void:
    _target_floor = node._get_next_floor()
    _target_y_pos = _target_floor.global_position.y


func _do(delta: float) -> void:
    if node.global_position.y == _target_y_pos:
        parent.transition_to(idle_state)
        return
    
    node._move_to_floor(delta, _target_y_pos)