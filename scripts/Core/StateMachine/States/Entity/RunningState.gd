class_name ERunningState
extends State


const TRAVEL_SPEED = 1.5

@export var idle_state: EIdleState
@export var elevator_shaft_state: EElevatorShaft
@export var nav_running_cstate: ENavigationRunningCState

var target_room: Room
var _target_pos: Vector3
var nav_state: bool = false


func _enter(_msg={}) -> void:
    _target_pos = node.map_path.pop_next_target_pos()


func _exit() -> void:
    pass


func _do(delta: float) -> void:
    if nav_state:
        return

    if _target_pos == node.global_position:
        if node.map_path.is_empty():
            if node.assigned_room.has_dweller(node) and !nav_state:
                nav_state = true
                
                nav_running_cstate.do()
                await nav_running_cstate.completed

                nav_state = false
                parent.transition_to(idle_state)
                return

            parent.transition_to(idle_state)
            return
        
        if node.map_path.get_current_room() is ElevatorShaft:
            parent.transition_to(elevator_shaft_state)
            return

        _target_pos = node.map_path.pop_next_target_pos()
    
    node.move_to_position(delta, _target_pos, TRAVEL_SPEED)