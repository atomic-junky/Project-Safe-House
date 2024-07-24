@tool
@icon("res://assets/editor/icons/State.svg")
class_name State extends Node
## Base class for all states.
## 
## A [State] must be a child of a [StateMachine] and it executes logic when active.[br]
## To implement your logic you can override the [code]_on_enter[/code], [code]_on_update[/code] and [code]_on_exit[/code] methods when extending the node's script.[br]
## A [State] can be composed of [Transition] to transition automatically to another [State].


## Signal used by a [StateMachine] to transition between states.
signal transitioned(new_state: State)

## List of [Transition] from this state.
var transitions: Array[Transition] = []


func _ready() -> void:
	# Don't run in editor
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
		return
	
	for transition: Node in get_children():
		if transition is Transition:
			transitions.append(transition)
		else:
			push_warning("State contains child which is not 'Transition'")


func _load_process(actor: Node) -> void:
	_load(actor)
	for transition: Transition in transitions:
		transition._load(actor)


## Call to load parent [StateMachine].
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
 
	if !get_parent() is StateMachine:
		warnings.append("Parent of this node is not a StateMachine.")
	
	var children: Array = get_children()

	for child in children:
		if not child is Transition:
			warnings.append("Node '" + child.get_name() + "' is not a Transition.")

	return warnings
