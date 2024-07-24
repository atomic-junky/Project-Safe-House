class_name StateMachineDebugLabel
extends Label3D


@export var machine: StateMachine


func _ready() -> void:
	rotation_degrees.y = 180
	no_depth_test = true
	fixed_size = true


func _process(_delta: float) -> void:
	var state = machine.active_state
	var transition = machine._active_transition
	if transition:
		text = transition.name
		return
	text = state.name
