class_name RoomFactory extends Node
## Factory for creating room instances.
##
## This factory provides a unified interface for creating rooms,
## supporting both legacy Room classes and new RoomEntity + components.
## Allows gradual migration to the new architecture.


## Create a PowerGenerator room
static func create_power_generator() -> Node:
	# For now, return the legacy class
	# TODO: Migrate to RoomEntity + components
	return PowerGenerator.new()


## Create a LivingRoom
static func create_living_room() -> Node:
	return LivingRoom.new()


## Create a Diner
static func create_diner() -> Node:
	return Diner.new()


## Create a WaterTreatment room
static func create_water_treatment() -> Node:
	return WaterTreatment.new()


## Create an ElevatorShaft
static func create_elevator_shaft() -> Node:
	return ElevatorShaft.new()


## Create a VaultDoor
static func create_vault_door() -> Node:
	return VaultDoor.new()


## Create an EmptyLocation
static func create_empty_location() -> Node:
	return EmptyLocation.new()


## Create a room from a room type ID
static func create_room(room_type: int) -> Node:
	match room_type:
		RoomList.POWER_GENERATOR:
			return create_power_generator()
		RoomList.LIVING_ROOM:
			return create_living_room()
		RoomList.DINER:
			return create_diner()
		RoomList.WATER_TREATMENT:
			return create_water_treatment()
		RoomList.ELEVATOR:
			return create_elevator_shaft()
		RoomList.VAULTDOOR:
			return create_vault_door()
		_:
			push_error("Unknown room type: " + str(room_type))
			return null


## Example of new-style room creation (for future migration)
## This shows how to create a RoomEntity with components
static func create_power_generator_new_style() -> RoomEntity:
	# Create room data
	var room_data = RoomData.new()
	room_data.room_id = "power_generator"
	room_data.room_name = "Power Generator"
	room_data.category = "Production"
	room_data.max_size = 3
	room_data.build_cost = 100
	room_data.meshes = {
		1: MeshLink._meshes.LIVING_ROOM_1L,
		2: MeshLink._meshes.LIVING_ROOM_2L,
		3: MeshLink._meshes.LIVING_ROOM_3L
	}
	
	# Create room entity
	var room = RoomEntity.new(room_data)
	
	# Add production component
	var production = ProductionComponent.new()
	production.resource_type = "Power"
	production.base_production_rate = 10.0
	production.production_cycle_time = 5.0
	room.add_child(production)
	room.production = production
	
	# Workspace component is added by default in RoomEntity._setup_components()
	
	return room
