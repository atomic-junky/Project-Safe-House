class_name DwellerManager extends Node
## Manager for dweller management and assignment.
##
## This manager handles dweller spawning, room assignment,
## and dweller lifecycle management.


## Signal emitted when a dweller is spawned
signal dweller_spawned(dweller: DwellerEntity)

## Signal emitted when a dweller is removed
signal dweller_removed(dweller: DwellerEntity)

## Signal emitted when dweller is assigned to room
signal dweller_assigned(dweller: DwellerEntity, room: RoomEntity)


## Reference to the shelter core
var shelter: Node3D

## Container for dwellers
var dweller_container: Node

## Currently selected dweller for drag & drop
var selected_dweller: DwellerEntity = null

## All active dwellers in the vault
var dwellers: Array[DwellerEntity] = []


## Initialize the dweller manager
func _init(shelter_node: Node3D, dweller_cont: Node) -> void:
	shelter = shelter_node
	dweller_container = dweller_cont


## Spawn a new dweller
func spawn_dweller() -> DwellerEntity:
	# Load dweller scene
	var dweller_scene = load("res://objects/dwellers/Dweller.tscn")
	if not dweller_scene:
		push_error("Could not load dweller scene")
		return null
	
	var dweller = dweller_scene.instantiate() as DwellerEntity
	if not dweller:
		push_error("Failed to instantiate dweller")
		return null
	
	dweller_container.add_child(dweller)
	dwellers.append(dweller)
	
	dweller_spawned.emit(dweller)
	
	return dweller


## Remove a dweller from the vault
func remove_dweller(dweller: DwellerEntity) -> void:
	if dweller in dwellers:
		dwellers.erase(dweller)
	
	# Unassign from room if assigned
	if dweller.work and dweller.work.assigned_room:
		dweller.work.leave_room()
	
	dweller_removed.emit(dweller)
	dweller.queue_free()


## Assign a dweller to a room
func assign_dweller_to_room(dweller: DwellerEntity, room: RoomEntity) -> bool:
	if not dweller or not room:
		return false
	
	# Check if room is full
	if room.is_full():
		return false
	
	# Don't assign to elevator or empty location
	if room is ElevatorShaft or room is EmptyLocation:
		return false
	
	# Assign using work component
	var success = false
	if dweller.work:
		success = dweller.work.assign_to_room(room)
	
	if success:
		dweller_assigned.emit(dweller, room)
	
	return success


## Move dweller to a room
func move_dweller_to_room(dweller: DwellerEntity, room: RoomEntity) -> void:
	if not dweller or not room:
		return
	
	# Don't move to same room
	if dweller.work and dweller.work.assigned_room == room:
		return
	
	# Assign and path to room
	if assign_dweller_to_room(dweller, room):
		dweller.path_to_room(room)


## Select a dweller for drag & drop
func select_dweller(dweller: DwellerEntity) -> void:
	selected_dweller = dweller


## Deselect current dweller
func deselect_dweller() -> void:
	selected_dweller = null


## Get dweller at specific position
func get_dweller_at_position(position: Vector3, threshold: float = 0.5) -> DwellerEntity:
	for dweller in dwellers:
		if dweller.global_position.distance_to(position) < threshold:
			return dweller
	return null


## Get all dwellers in a specific room
func get_dwellers_in_room(room: RoomEntity) -> Array[DwellerEntity]:
	var room_dwellers: Array[DwellerEntity] = []
	
	for dweller in dwellers:
		if dweller.work and dweller.work.assigned_room == room:
			room_dwellers.append(dweller)
	
	return room_dwellers


## Get count of all dwellers
func get_dweller_count() -> int:
	return dwellers.size()
