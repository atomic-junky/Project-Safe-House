class_name ERunningState
extends State


const TRAVEL_SPEED = 1.5

@export var idle_state: EIdleState
@export var elevator_shaft_state: EElevatorShaft

var target_room: Room
var _target_pos: Vector3


func _enter(_msg={}) -> void:
    _target_pos = node.map_path.pop_next_target_pos()


func _exit() -> void:
    pass


func _do(delta: float) -> void:
    if _target_pos == node.global_position:
        if node.map_path.is_empty():
            parent.transition_to(idle_state)
            return
        
        if node.map_path.get_current_room() is Elevator:
            parent.transition_to(elevator_shaft_state)
            return

        _target_pos = node.map_path.pop_next_target_pos()
    
    node.move_to_position(delta, _target_pos, TRAVEL_SPEED)