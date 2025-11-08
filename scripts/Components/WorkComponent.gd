class_name WorkComponent extends Component
## Component that manages dweller work behavior.
##
## This component handles work assignment, work state, and productivity.


## Signal emitted when dweller starts working
signal work_started(room: RoomEntity)

## Signal emitted when dweller stops working
signal work_stopped(room: RoomEntity)

## Signal emitted when productivity changes
signal productivity_changed(new_productivity: float)


## The room where the dweller is currently assigned
var assigned_room: RoomEntity = null

## Whether the dweller is currently working
var is_working: bool = false

## Current work productivity (0.0 to 1.0+)
var productivity: float = 0.0


## Assign dweller to work in a room
func assign_to_room(room: RoomEntity) -> bool:
	if assigned_room == room:
		return true
	
	# Leave previous room
	if assigned_room:
		leave_room()
	
	# Join new room
	assigned_room = room
	var success = room.register_dweller(entity as Dweller)
	
	if success:
		work_started.emit(room)
	
	return success


## Leave current work assignment
func leave_room() -> void:
	if not assigned_room:
		return
	
	assigned_room.forget_dweller(entity as Dweller)
	work_stopped.emit(assigned_room)
	assigned_room = null
	is_working = false


## Start working
func start_work() -> void:
	if not assigned_room:
		return
	
	is_working = true
	_update_productivity()


## Stop working
func stop_work() -> void:
	is_working = false
	productivity = 0.0


## Update productivity based on dweller stats and room
func _update_productivity() -> void:
	if not assigned_room:
		productivity = 0.0
		return
	
	# Base productivity
	var base_prod = 0.5
	
	# Get stats component if available
	var stats_component = entity.get_node_or_null("StatsComponent")
	if stats_component:
		# Room's primary stat affects productivity
		var room_stat = _get_room_primary_stat()
		base_prod = 0.3 + (room_stat / 10.0) * 0.7
	
	# Apply room level bonus
	if assigned_room.upgrade:
		base_prod *= (1.0 + assigned_room.upgrade.get_level_bonus())
	
	productivity = base_prod
	productivity_changed.emit(productivity)


## Get the relevant stat for the assigned room
func _get_room_primary_stat() -> float:
	# Default implementation - override or enhance with stats component
	return 5.0


## Get work position in current room
func get_work_position() -> Vector3:
	if assigned_room:
		return assigned_room.get_work_position(entity as Dweller)
	return Vector3.ZERO


## Check if dweller can work in a room
func can_work_in_room(room: RoomEntity) -> bool:
	if not room:
		return false
	return not room.is_full()
