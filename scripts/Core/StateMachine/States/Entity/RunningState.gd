class_name ERunningState extends State


const TRAVEL_SPEED = 1.5

@export var idle_state: EIdleState
@export var elevator_shaft_state: EElevatorShaft

var target_room: Room
var _target_pos: Vector3
var nav_state: bool = false
var waiting: bool = false

func _enter(actor: Node) -> void:
	var next_room = actor.map_path.get_next_room()
	var current_room = actor.map_path.get_current_room()
	if current_room is EmptyLocation and next_room is VaultDoor:
		waiting = true
		next_room.ask_to_open()
		await next_room.open
		waiting = false

	_target_pos = actor.map_path.pop_next_target_pos()


func _update(delta: float, actor: Node) -> void:
	if nav_state or waiting:
		return

	if _target_pos and _target_pos == actor.global_position:
		if actor.map_path.is_empty():
			if actor.assigned_room.has_dweller(actor):
				return

			transitioned.emit(idle_state)
			return
		
		if actor.map_path.get_current_room() is ElevatorShaft:
			transitioned.emit(elevator_shaft_state)
			return

		_target_pos = actor.map_path.pop_next_target_pos()
	
	actor.move_to_position(delta, _target_pos, TRAVEL_SPEED)
