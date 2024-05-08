class_name StateMachineDebugLabel
extends Label3D


@export var machine: StateMachine


func _ready():
	rotation_degrees.y = 180
	no_depth_test = true
	fixed_size = true


func _process(_delta) -> void:
	var state = machine.state
	text = state.name