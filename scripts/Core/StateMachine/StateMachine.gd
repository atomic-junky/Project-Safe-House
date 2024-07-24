@tool
@icon("res://assets/editor/icons/StateMachine.svg")
class_name StateMachine extends Node
## Base class for all state machines.
## 
## A [StateMachine] is used to manage several states.[br]
## To implement your logic you can override the [method _on_enter], [method _on_update] and [method _on_exit] methods when extending the node's script.[br]
## A [State] can be composed of [Transition] to transition automatically to another [State].


## Signal used to transition between states.
signal transitioned(new_state: State)

## Whether the StateMachine should start automatically.
@export var autostart: bool = true
## The actor of the StateMachine.
@export var actor: Node
## The initial [State] of the StateMachine.
@export var initial_state: State

## The current active [State].
var active_state: State

var _states: Dictionary = {}
var _active_transition: Transition 


func _ready() -> void:
	# Don't run in editor
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
		return
	
	transitioned.connect(_on_child_transitioned)
	
	if autostart:
		_start()


func _start() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child
			
			child.transitioned.connect(_on_child_transitioned)
			child._load_process(actor)
		else:
			push_warning("State machine contains child which is not 'State'")
	
	initial_state._enter(actor)
	active_state = initial_state


func _on_child_transitioned(state: State) -> void:
	var new_state = _states.get(state.name)
 
	if new_state == null:
		return push_warning("Called transition on a state that does not exist")
	
	if new_state != active_state:
		active_state._exit(actor)
		new_state._enter(actor)
		
		active_state = new_state


func _process(delta: float) -> void:
	if active_state != null:
		for transition: Transition in active_state.transitions:
			if _active_transition == transition:
				continue
			
			if transition._is_valid_logic(actor):
				_active_transition = transition
				transition._enter(actor)
				
				active_state._exit(actor)
				active_state = null
				
				await transition.completed
				
				_active_transition = null
				transition.next_state._enter(actor)
				active_state = transition.next_state
				break
	
		active_state._update(delta, actor)
	
	if _active_transition != null:
		_active_transition._update(delta, actor)


func _physics_process(delta: float) -> void:
	if active_state != null:
		active_state._physics_update(delta, actor)
	
	if _active_transition != null:
		_active_transition._physics_update(delta, actor)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array = []
 
	if not initial_state:
		warnings.append("Initial state is not set.")
		
	if not actor:
		warnings.append("Actor is not set.")
	
	var children: Array = get_children()

	if children.size() == 0:
		warnings.append("No states found.")

	for child in children:
		if not child is State:
			warnings.append("Node '" + child.get_name() + "' is not a State.")

	return warnings
