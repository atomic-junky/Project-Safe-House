class_name EElevatorShaft extends State


const TRAVEL_SPEED = 1.5

@export var idle_platform_state: EIdlePlatformState

var current_shaft: ElevatorShaft
var _target_pos: Vector3


func _enter(actor: Node) -> void:
	current_shaft = actor.map_path.get_current_room()

	actor.map_path.pop_next_target_pos()
	_target_pos = current_shaft.wait_for_elevator(actor)

func _update(delta: float, actor: Node) -> void:
	if _target_pos != actor.global_position:
		if actor.map_path.is_empty():
			return

		actor.move_to_position(delta, _target_pos, TRAVEL_SPEED)
	
