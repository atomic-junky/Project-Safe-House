@tool
class_name EPMovingState extends State


@export var idle_state: EPIdleState

var _target_floor: ElevatorShaft
var _target_y_pos: float
var _waiting: bool = false


func _enter(actor: Node) -> void:
	actor.accept_dweller = false
	_waiting = true
	_target_floor = actor._get_next_floor()
	_target_y_pos = _target_floor.global_position.y

	var elevator_shaft = actor._current_elevator
	if elevator_shaft.is_open:
		await actor._current_elevator.close
	_waiting = false


func _update(delta: float, actor: Node) -> void:
	if _waiting:
		return

	if actor.global_position.y == _target_y_pos:
		transitioned.emit(idle_state)
		actor._requests.erase(actor._current_elevator)
		return

	actor._move_to_floor(delta, _target_y_pos)
