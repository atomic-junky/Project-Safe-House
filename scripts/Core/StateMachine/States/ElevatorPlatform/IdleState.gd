@tool
class_name EPIdleState extends State


@export var moving_state: EPMovingState

var _idle_exit: bool = false
var _is_waiting: bool = true


func _enter(actor: Node) -> void:        
	_idle_exit = false
	_is_waiting = true
	actor.accept_dweller = true

	if actor._current_elevator:
		await actor._current_elevator.open
	
	_is_waiting = false

func _update(_delta: float, actor: Node) -> void:
	if actor._can_go() and (actor.is_full() or actor._current_elevator.is_empty()):
		transitioned.emit(moving_state)
