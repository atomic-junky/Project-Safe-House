class_name VisualComponent extends Component
## Component that manages room visual representation.
##
## This component handles mesh selection, visual updates,
## and rendering based on room state.


## Signal emitted when visual changes
signal visual_updated


## Reference to the room's 3D node in the scene
var room_node: Node3D

## Meshes for different room sizes
var meshes: Dictionary = {}

## Current room size (1-3)
var current_size: int = 1


## Set up the visual component with meshes
func setup_meshes(mesh_dict: Dictionary) -> void:
	meshes = mesh_dict


## Get the mesh for current size
func get_current_mesh() -> Dictionary:
	return meshes.get(current_size, {})


## Update the room size and visual
func set_size(new_size: int) -> void:
	if new_size < 1 or new_size > 3:
		push_warning("Invalid room size: " + str(new_size))
		return
	
	current_size = new_size
	visual_updated.emit()


## Set the room node reference
func set_room_node(node: Node3D) -> void:
	room_node = node
	visual_updated.emit()


## Get the global position of the room
func get_global_position() -> Vector3:
	if room_node:
		return room_node.global_position
	return Vector3.ZERO


## Get the local position of the room
func get_position() -> Vector3:
	if room_node:
		return room_node.position
	return Vector3.ZERO


## Get the navigation region if it exists
func get_navigation_region() -> NavigationRegion3D:
	if room_node:
		return room_node.get_node_or_null("NavigationRegion3D")
	return null


## Show/hide the room visual
func set_visible(visible: bool) -> void:
	if room_node:
		room_node.visible = visible
