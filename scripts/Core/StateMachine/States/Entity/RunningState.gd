@tool
class_name ERunningState extends State

const TRAVEL_SPEED = 1.5

@export var idle_state: EIdleState
@export var elevator_shaft_state: EElevatorShaft

var _target_pos: Vector3 = Vector3.ZERO
var nav_state: bool = false
var waiting: bool = false



func _enter(actor: Node) -> void:
	_target_pos = Vector3.ZERO
	waiting = false
	nav_state = false
	
	if actor.map_path == null or actor.map_path.is_empty():
		return
	
	var next_room = actor.map_path.get_next_room()
	if next_room is VaultDoor:
		waiting = true
		next_room.open_request(_on_vault_door_open.bind(actor))
		return

	_target_pos = actor.map_path.pop_next_target_pos()


func _on_vault_door_open(actor: Node) -> void:
	waiting = false
	if actor.map_path != null and !actor.map_path.is_empty():
		_target_pos = actor.map_path.pop_next_target_pos()


func _update(delta: float, actor: Node) -> void:
	if nav_state or waiting or _target_pos == Vector3.ZERO:
		return

	if actor.global_position.distance_to(_target_pos) < 0.1:
		if actor.map_path == null or actor.map_path.is_empty():
			if actor.assigned_room.has_dweller(actor):
				return
			transitioned.emit(idle_state)
			return

		var current_room = actor.map_path.get_current_room()
		if current_room is ElevatorShaft:
			transitioned.emit(elevator_shaft_state)
			return

		_target_pos = actor.map_path.pop_next_target_pos()
		return

	actor.move_to_position(delta, _target_pos, TRAVEL_SPEED)
