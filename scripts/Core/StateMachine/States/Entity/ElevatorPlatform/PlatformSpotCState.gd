class_name EPlatformSpotCState
extends CompositeState


const TRAVEL_SPEED = 1.5

@export var idle_platform_state: EIdlePlatformState

var elevator: ElevatorShaft
var platform: ElevatorPlatform
var _target_pos: Vector3


func _enter(_msg={}) -> void:
    elevator = node.map_path.prev_room

    _target_pos = elevator._platform.get_dweller_pos(node)


func _do(delta: float) -> void:
    if _target_pos == node.global_position:
        completed.emit()
        return

    node.move_to_position(delta, _target_pos, TRAVEL_SPEED)
    
