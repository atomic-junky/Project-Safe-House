class_name Component extends Node
## Base class for all components in the game.
##
## Components provide modular, reusable behavior that can be attached to nodes.
## This follows composition over inheritance principle and Godot 4+ best practices.
## 
## Components should be small, focused, and handle a single responsibility.
## They communicate with other components through signals and direct references.


## Signal emitted when the component is initialized
signal initialized

## The entity/node this component is attached to
var entity: Node


## Called when the component is added to the scene tree
func _ready() -> void:
	if not Engine.is_editor_hint():
		entity = get_parent()
		_initialize()


## Override this method to initialize component-specific logic
func _initialize() -> void:
	initialized.emit()


## Override this method to handle component updates
func _update(_delta: float) -> void:
	pass


## Override this method to handle component physics updates
func _physics_update(_delta: float) -> void:
	pass


## Override this method to clean up when component is removed
func _cleanup() -> void:
	pass


## Called when component is removed from tree
func _exit_tree() -> void:
	_cleanup()
