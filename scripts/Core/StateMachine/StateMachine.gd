class_name StateMachine
extends Node

@export var initial_state: State

@export_group("Reference")
@export var node: Node

var state: State
var last_state: State:
	get:
		return state.state

func _ready() -> void:
	_set_state(initial_state)

func transition_to(target_state: State, msg={}, force_reset: bool=false):
	if !target_state:
		Logger.warn("Can't transition to target state because state is Nil")
		return

	assert(not target_state is CompositeState)

	_set_state(target_state, msg, force_reset)

func _set_state(new_state: State, msg={}, force_reset: bool=false) -> State:
	if state != new_state or force_reset:
		if state:
			state._exit()
		
		state = new_state
		state.initialise(self)
		state._enter(msg)

	return state

func _process(delta: float):
	if state:
		state.do_branch(delta)

func get_active_state_branch(list=null):
	if list == null:
		list = []
	
	if state == null:
		return list
	else:
		list.add(state)
		return state.machine.get_active_state_branch(list)