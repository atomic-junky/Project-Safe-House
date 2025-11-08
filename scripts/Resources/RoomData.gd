class_name RoomData extends Resource
## Resource defining room type properties.
##
## This resource holds all the static data for a room type,
## following Godot's data-driven design pattern.


## Unique identifier for the room type
@export var room_id: String = ""

## Display name of the room
@export var room_name: String = ""

## Description of the room
@export_multiline var description: String = ""

## Maximum size the room can be (1-3 tiles wide)
@export_range(1, 3) var max_size: int = 3

## Whether the room can be destroyed
@export var destroyable: bool = true

## Base cost to build the room
@export var build_cost: int = 100

## Meshes for different room sizes (1L, 2L, 3L)
@export var meshes: Dictionary = {}

## Whether the room requires power
@export var requires_power: bool = false

## Whether the room requires water
@export var requires_water: bool = false

## Category of the room (production, living, utility, etc.)
@export_enum("Production", "Living", "Utility", "Special") var category: String = "Living"

## Maximum number of dwellers that can work in this room
@export var max_workers: int = 2

## SPECIAL stat that affects work efficiency in this room
@export_enum("Strength", "Perception", "Endurance", "Charisma", "Intelligence", "Agility", "Luck") var primary_stat: String = "Strength"


## Returns the mesh for a given room size
func get_mesh(size: int) -> Dictionary:
	return meshes.get(size, {})
