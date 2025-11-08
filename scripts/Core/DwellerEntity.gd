class_name DwellerEntity extends Node3D
## Modular dweller entity using component-based architecture.
##
## This class represents a vault dweller, using composition for flexible behavior.
## Dwellers are configured with components for movement, work, stats, etc.


## Signal emitted when dweller transfers to elevator
@warning_ignore("unused_signal")
signal elevator_transfer


## Unique identifier for this dweller
var id: String = UUID.v4()

## State machine for behavior control
@export var machine: StateMachine

## Components
var movement: MovementComponent
var work: WorkComponent

## Legacy compatibility properties (delegated to components)
var assigned_room:
	get:
		return work.assigned_room if work else null
	set(value):
		if work and value:
			work.assign_to_room(value)

var is_traveling:
	get:
		return movement.is_traveling if movement else false
	set(value):
		if movement:
			movement.is_traveling = value

var map_path:
	get:
		return movement.current_path if movement else null
	set(value):
		if movement:
			movement.set_path(value)

var matrix_position:
	get:
		return movement.get_matrix_position() if movement else Vector2i.ZERO


## Initialize the dweller
func _ready() -> void:
	_setup_components()
	
	# Set initial position
	position.y = 47.095
	position.x = -0.8
	
	Logger.info("Dweller(" + id + ") created")


## Set up components
func _setup_components() -> void:
	# Create movement component
	movement = MovementComponent.new()
	movement.name = "MovementComponent"
	add_child(movement)
	
	# Create work component
	work = WorkComponent.new()
	work.name = "WorkComponent"
	add_child(work)


## Calculate path to a target room
func path_to_room(target_room: RoomEntity) -> void:
	if not movement or not work:
		return
	
	var parent = _get_main_parent()
	var matrix: Matrix = parent._matrix
	var max_height = matrix.size.y
	
	var start: Vector2i = Vector2i(matrix_position.x, max_height - matrix_position.y - 1)
	var end: Vector2i = target_room.positions[0]
	
	# Unassign from old room and assign to new room
	if work.assigned_room:
		work.leave_room()
	
	work.assign_to_room(target_room)
	
	# Calculate and set path
	var path = movement.calculate_path(start, end)
	if path:
		movement.set_path(path)


## Move towards a position (delegates to movement component)
func move_to_position(delta: float, target_pos: Vector3, 
					  h_speed: float = 1.5, v_speed: float = 0.5) -> void:
	if movement:
		movement.move_to_position(delta, target_pos, h_speed, v_speed)


## Get best path between two positions
func best_path(start: Vector2i, end: Vector2i) -> MapPath:
	if movement:
		return movement.calculate_path(start, end)
	return null


## Get the main parent (shelter)
func _get_main_parent() -> Node:
	return get_parent().get_parent()


## Get navigation agent
func _get_navigation_agent() -> NavigationAgent3D:
	if movement:
		return movement.navigation_agent
	return null


## Get a component by type
func get_component(component_type) -> Component:
	for child in get_children():
		if is_instance_of(child, component_type):
			return child
	return null
