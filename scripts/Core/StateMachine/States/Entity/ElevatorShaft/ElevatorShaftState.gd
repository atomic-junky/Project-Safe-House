class_name EElevatorShaft
extends State


const TRAVEL_SPEED = 1.5

@export var platform_transition_state: EToPlatformTransitionCState
@export var platform_spot_state: EPlatformSpotCState
@export var idle_platform_state: EIdlePlatformState

var current_shaft: ElevatorShaft
var _target_pos: Vector3

var _waiting_for_transfer: bool = true


func _enter(_msg={}) -> void:
    _waiting_for_transfer = true
    current_shaft = node.map_path.get_current_room()

    node.map_path.pop_next_target_pos()
    _target_pos = current_shaft.wait_for_elevator(node)

    await node.elevator_transfer
    _waiting_for_transfer = false
    
    await platform_transition_state.do()
    await platform_spot_state.do()
    parent.transition_to(idle_platform_state)


func _do(delta: float) -> void:
    if _waiting_for_transfer and _target_pos != node.global_position:
        if node.map_path.is_empty():
            return

        node.move_to_position(delta, _target_pos, TRAVEL_SPEED)
    
