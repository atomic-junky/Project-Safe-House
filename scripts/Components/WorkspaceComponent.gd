class_name WorkspaceComponent extends Component
## Component that manages dweller work spots in a room.
##
## This component handles assigning dwellers to work positions,
## tracking who is working, and managing work spot availability.


## Signal emitted when a dweller is assigned to a work spot
signal dweller_assigned(dweller: Dweller)

## Signal emitted when a dweller is removed from a work spot
signal dweller_removed(dweller: Dweller)

## Signal emitted when all work spots are filled
signal workspace_full

## Signal emitted when workspace has available spots
signal workspace_available


## The working pool that manages work positions
var working_pool: WorkingPool

## List of dweller IDs currently in this room
var dwellers: Array = []


## Initialize the workspace with a working pool
func _initialize() -> void:
	super._initialize()
	
	# Default initialization if not set
	if not working_pool:
		var params: WorkingPoolParameters = WorkingPoolParameters._default()
		working_pool = WorkingPool.new(params)


## Set up the working pool from parameters
func setup_working_pool(params: WorkingPoolParameters) -> void:
	working_pool = WorkingPool.new(params)


## Register a dweller to work in this room
func register_dweller(dweller: Dweller, room_size: int) -> bool:
	if not dwellers.has(dweller.id):
		dwellers.append(dweller.id)
	
	var success: bool = working_pool._assign_dweller(room_size, dweller)
	
	if success:
		dweller_assigned.emit(dweller)
		
		if working_pool.is_full(room_size):
			workspace_full.emit()
	
	return success


## Unregister a dweller from this room
func forget_dweller(dweller: Dweller, room_size: int) -> void:
	if dwellers.has(dweller.id):
		dwellers.erase(dweller.id)
	
	if working_pool.has_dweller(room_size, dweller):
		working_pool._deassign_dweller(room_size, dweller)
		dweller_removed.emit(dweller)
		workspace_available.emit()


## Check if a dweller is working in this room
func has_dweller(dweller: Dweller, room_size: int) -> bool:
	return working_pool.has_dweller(room_size, dweller)


## Check if all work spots are filled
func is_full(room_size: int) -> bool:
	return working_pool.is_full(room_size)


## Check if workspace is empty
func is_empty(room_size: int) -> bool:
	return working_pool.is_empty(room_size)


## Get the work position for a specific dweller
func get_work_position(dweller: Dweller, room_size: int) -> Vector3:
	return working_pool.get_position(room_size, dweller)


## Get the number of available work spots
func get_available_spots(room_size: int) -> int:
	var all_spots = working_pool._spots.get(room_size, [])
	var free_spots = all_spots.filter(func(s): return s.dweller == null)
	return free_spots.size()


## Get the total number of work spots
func get_total_spots(room_size: int) -> int:
	return working_pool._spots.get(room_size, []).size()
