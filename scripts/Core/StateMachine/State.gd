class_name State
extends Node


signal completed

var start_time: float
var is_complete: bool = false
var time: float

var machine: StateMachine
var parent: StateMachine

var node: Node :
	get = _get_node


var state: State :
	get:
		return machine.state if machine else null


func set_state(new_state: State, msg={}, force_reset: bool = false) -> State:
	return machine._set_state(new_state, msg, force_reset)


func initialise(_parent: StateMachine) -> void:
	parent = _parent
	machine = StateMachine.new()
	is_complete = false
	start_time = Time.get_unix_time_from_system()


func _enter(_msg={}) -> void: pass
func _do(_delta: float) -> void: pass
func _exit() -> void: pass


func do_branch(delta: float) -> void:
	_do(delta)

	if state:
		state.do_branch(delta)


func _get_node():
	return parent.node if parent else null