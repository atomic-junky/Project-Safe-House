class_name EIdlePlatformState
extends State


const TRAVEL_SPEED = 1.5

@export var shaft_transtion_state: EToShaftTransitionCState
@export var running_state: ERunningState

var current_elevator: Elevator
var platform: ElevatorPlatform


func _enter(_msg={}) -> void:
    current_elevator = node.map_path.prev_room

    platform = current_elevator._platform
    platform.request(node.map_path.get_current_room())


func _do(_delta: float) -> void:
    if platform._current_elevator == node.map_path.get_current_room() and not node.map_path.get_next_room() is Elevator:
        if shaft_transtion_state._active:
            return
        
        platform._deassign_dweller(node)

        await shaft_transtion_state.do()
        parent.transition_to(running_state)
    
