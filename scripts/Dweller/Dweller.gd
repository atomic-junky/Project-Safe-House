class_name Dweller extends ShelterEntity

## Dweller now uses ECS system for gameplay logic
## This script acts as a bridge between the Node3D visual representation
## and the ECS components that drive the dweller's behavior

signal travel_requested(room: AbstractRoom)
signal travel_started(room: AbstractRoom)
signal travel_failed(room: AbstractRoom)
signal travel_completed(room: AbstractRoom)

signal work_assigned(room: AbstractRoom)
signal work_started(room: AbstractRoom)
signal work_completed(room: AbstractRoom)

signal drag_started(start_position: Vector3)
signal drag_ended(end_position: Vector3, target_room: AbstractRoom)

# ECS entity ID
var ecs_entity_id: int = -1

# Cached component references (synced from ECS each frame)
var ecs_transform: Variant = null
var ecs_movement: Variant = null
var ecs_navigation: Variant = null
var ecs_draggable: Variant = null
var ecs_work: Variant = null

var _navigation_helper: DwellerNavigation = null
var _previous_nav_state: int = Navigation.NavState.IDLE
var _active_map_path: MapPath = null


func _ready() -> void:
	position.y = 47.095
	position.x = -0.8
	_navigation_helper = DwellerNavigation.new(self)

	# Register this node with DwellerCountContainer to get ECS entity ID
	await get_tree().process_frame
	_register_with_ecs()


func _process(_delta: float) -> void:
	"""Each frame: sync position from ECS and react to navigation events."""
	if ecs_entity_id < 0:
		return

	_update_ecs_component_refs()
	_sync_ecs_transform_from_node()
	_handle_navigation_state_changes()


func _register_with_ecs() -> void:
	"""Register this dweller node with ECS system."""
	var parent = get_parent()
	var dweller_container = parent

	# Find DwellerCountContainer in the scene tree
	while dweller_container and dweller_container.name != "DwellerCountContainer":
		dweller_container = dweller_container.get_parent()

	if dweller_container:
		# Get the ECS entity ID for this node
		ecs_entity_id = dweller_container.get_ecs_entity_for_node(self)
		print("Dweller registered with ECS entity ID: %d" % ecs_entity_id)
	else:
		push_error("Dweller: Could not find DwellerCountContainer!")


func _update_ecs_component_refs() -> void:
	"""Refresh component references from ECS."""
	if ecs_entity_id < 0 or not ECSManager:
		return

	ecs_transform = ECSManager.get_component(ecs_entity_id, "Transform")
	ecs_movement = ECSManager.get_component(ecs_entity_id, "Movement")
	ecs_navigation = ECSManager.get_component(ecs_entity_id, "Navigation")
	ecs_draggable = ECSManager.get_component(ecs_entity_id, "Draggable")
	ecs_work = ECSManager.get_component(ecs_entity_id, "Work")


func _sync_ecs_transform_from_node() -> void:
	"""Write this node's transform back to ECS each frame."""
	if ecs_transform:
		ecs_transform.position = global_position


func _handle_navigation_state_changes() -> void:
	"""Emit navigation signals when ECS state changes."""
	if ecs_navigation == null:
		_previous_nav_state = Navigation.NavState.IDLE
		return

	if ecs_navigation.current_state == Navigation.NavState.TRAVELING:
		var path_finished: bool = map_path == null or map_path.is_empty()
		var movement_active: bool = ecs_movement != null and ecs_movement.is_moving
		if path_finished and !movement_active:
			_finish_travel(ecs_navigation.target_room)

	var current_state: int = ecs_navigation.current_state

	if (
		current_state == Navigation.NavState.ARRIVED
		and _previous_nav_state != Navigation.NavState.ARRIVED
	):
		var arrived_room: AbstractRoom = ecs_navigation.target_room
		if arrived_room == null:
			arrived_room = ecs_navigation.current_room
			ecs_navigation.current_room = arrived_room

		if arrived_room != null:
			emit_signal("travel_completed", arrived_room)

		ecs_navigation.target_room = null
		ecs_navigation.current_state = Navigation.NavState.IDLE
		current_state = ecs_navigation.current_state

	_previous_nav_state = current_state


func travel_to_room(target_room: AbstractRoom) -> bool:
	"""Public API: compute path and push it into ECS navigation component."""
	if target_room == null or ecs_entity_id < 0:
		return false

	_update_ecs_component_refs()

	if ecs_navigation == null:
		return false

	var path: MapPath = null
	if _navigation_helper != null:
		path = _navigation_helper.calculate_path(target_room)

	if path == null:
		emit_signal("travel_failed", target_room)
		return false

	emit_signal("travel_requested", target_room)

	map_path = path
	_active_map_path = path

	if ecs_navigation:
		ecs_navigation.map_path = path
	ecs_navigation.target_room = target_room
	ecs_navigation.current_target_pos = Vector3.ZERO
	ecs_navigation.current_state = Navigation.NavState.TRAVELING
	ecs_navigation.is_waiting = false
	ecs_navigation.waiting_reason = &""

	if ecs_movement:
		ecs_movement.is_moving = false
		ecs_movement.target_position = global_position
		ecs_movement.velocity = Vector3.ZERO

	if ecs_navigation.current_state == Navigation.NavState.TRAVELING:
		emit_signal("travel_started", target_room)
		_previous_nav_state = Navigation.NavState.TRAVELING
	else:
		_finish_travel(target_room)

	return true


func path_to_room(target_room: AbstractRoom) -> void:
	"""Alias for travel_to_room (backward compatibility)."""
	travel_to_room(target_room)


func cancel_travel(clear_room_assignment: bool = false) -> void:
	"""Cancel current travel."""
	if ecs_entity_id < 0:
		return

	_update_ecs_component_refs()

	if ecs_navigation:
		ecs_navigation.reset()

	map_path = null
	_active_map_path = null

	if ecs_movement:
		ecs_movement.is_moving = false
		ecs_movement.target_position = global_position
		ecs_movement.velocity = Vector3.ZERO

	if _navigation_helper:
		_navigation_helper.cancel(clear_room_assignment)

	_previous_nav_state = Navigation.NavState.IDLE


func assign_to_work(room: AbstractRoom) -> bool:
	"""Assign dweller to work in a room."""
	if ecs_entity_id < 0:
		return false

	_update_ecs_component_refs()

	if ecs_work == null:
		return false

	ecs_work.assigned_room = room
	emit_signal("work_assigned", room)
	return true


func start_working() -> void:
	"""Start working in assigned room."""
	if ecs_entity_id < 0:
		return

	_update_ecs_component_refs()

	if ecs_work == null:
		return

	ecs_work.is_working = true
	emit_signal("work_started", ecs_work.assigned_room)


func stop_working() -> void:
	"""Stop working."""
	if ecs_entity_id < 0:
		return

	_update_ecs_component_refs()

	if ecs_work == null:
		return

	ecs_work.is_working = false
	emit_signal("work_completed", ecs_work.assigned_room)


func move_to_position(
	delta: float,
	target_pos: Vector3,
	h_speed: float = 1.5,
	v_speed: float = 0.5
) -> void:
	"""Override movement hook to keep ECS components synchronized."""
	var previous_position: Vector3 = global_position
	super.move_to_position(delta, target_pos, h_speed, v_speed)

	_update_ecs_component_refs()

	if ecs_transform:
		ecs_transform.position = global_position

	if ecs_movement:
		ecs_movement.target_position = target_pos
		var arrived: bool = global_position.distance_to(target_pos) <= MovementSystem.ARRIVAL_TOLERANCE
		ecs_movement.is_moving = not arrived
		var velocity: Vector3 = Vector3.ZERO
		if delta > 0.0:
			velocity = (global_position - previous_position) / delta
		ecs_movement.velocity = velocity

	if ecs_navigation:
		ecs_navigation.current_target_pos = target_pos


func _finish_travel(target_room: AbstractRoom) -> void:
	"""Finalize travel state and emit completion signals via navigation handler."""
	map_path = null
	_active_map_path = null

	if ecs_navigation:
		ecs_navigation.current_state = Navigation.NavState.ARRIVED
		ecs_navigation.current_room = target_room
		ecs_navigation.current_target_pos = Vector3.ZERO
		ecs_navigation.is_waiting = false
		ecs_navigation.waiting_reason = &""

	if ecs_movement:
		ecs_movement.is_moving = false
		ecs_movement.velocity = Vector3.ZERO


func is_idle() -> bool:
	"""Return true if navigation + movement are idle."""
	if ecs_entity_id < 0:
		return true

	_update_ecs_component_refs()

	var navigation_idle: bool = (
		ecs_navigation == null
		or ecs_navigation.current_state == Navigation.NavState.IDLE
	)
	var is_moving: bool = ecs_movement != null and ecs_movement.is_moving
	return navigation_idle and !is_moving


func is_traveling() -> bool:
	"""Return true if dweller is currently moving towards a waypoint."""
	if ecs_entity_id < 0:
		return false

	_update_ecs_component_refs()

	if ecs_navigation == null:
		return false

	if ecs_navigation.current_state == Navigation.NavState.TRAVELING:
		return true

	return ecs_movement != null and ecs_movement.is_moving
