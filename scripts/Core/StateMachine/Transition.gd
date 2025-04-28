@tool
@icon("res://assets/editor/icons/Transition.svg")
class_name Transition extends Node
## Base class for all transitions.
## 
## A [Transition] must be a child of a [State].
## A [Transition] is trigger when [method Transition._is_valid] return [code]true[/code] and if it's parent [State] is active.[br]
## It executes logic when active.
## To implement your logic you can override the [code]_on_enter[/code], [code]_on_update[/code] and [code]_on_exit[/code] methods when extending the node's script.


## Must be call when the transition is completed to transition to the next [State].
@warning_ignore("unused_signal")
signal completed

## The fallback [State] of this transition.
@export var next_state: State

## Whether this transition is active.
var active: bool = false
## The [State] to which this transition is linked
var state: State :
	get : return self.get_parent()
	set(val) : return

var _is_signal_valid: bool = false
var _register_signals: Array[Signal] = []


func _ready() -> void:
	# Don't run in editor
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
		return


func _reconnect_signals() -> void:
	for s in _register_signals:
		if s.is_connected(_signal_callback):
			continue
		s.connect(_signal_callback)


func _signal_callback() -> void:
	_is_signal_valid = true


## Register a signal used to trigger this transition.
func register_signal(r_signal: Signal) -> void:
	if r_signal in _register_signals:
		return
	_register_signals.append(r_signal)
	
	_reconnect_signals()


func _is_valid_logic(actor: Node) -> bool:
	if _is_signal_valid:
		_is_signal_valid = false
		return true
	return _is_valid(actor)

## Used to define the condition for this [Transition] to activate and switch to another [State].
func _is_valid(_actor: Node) -> bool:
	return false


## Call to load parent [State].
func _load(_actor: Node) -> void: pass


## Executes when the state is entered.
func _enter(_actor: Node) -> void: pass


## Executes every process call, if the state is active.
func _update(_delta: float, _actor: Node) -> void: pass


## Executes every physics process call, if the state is active.
func _physics_update(_delta: float, _actor: Node) -> void: pass


## Executes before the state is exited.
func _exit(_actor: Node) -> void: pass


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: Array = []
 
	if !get_parent() is State:
		warnings.append("Parent of this node is not a State.")
 
	if not next_state:
		warnings.append("Next state is not set.")

	return warnings
