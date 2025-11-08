class_name ShelterController extends Node3D
## Modular shelter controller using manager-based architecture.
##
## This controller coordinates between managers instead of handling
## everything directly, following single responsibility principle.


## UI reference
@export var roomSelectorInterface: PanelContainer = null

## Node references
@onready var shelter_map: AutoSceneMap = $AutoSceneMap
@onready var platform_container = $PlatformContainer
@onready var drag_body = $DragBody
@onready var dweller_container = $DwellerContainer
@onready var camera = $Camera

## Core data
var _matrix: Matrix = Matrix.new(14, 25)

## Managers
var room_manager: RoomManager
var elevator_manager: ElevatorManager
var build_manager: BuildManager
var dweller_manager: DwellerManager

## Pointer meshes for room selection
var _pointer_meshes = [
	MeshLink._meshes.POINTER_1L,
	MeshLink._meshes.POINTER_2L,
	MeshLink._meshes.POINTER_3L
]


## Initialize the shelter
func _ready() -> void:
	_initialize_managers()
	_setup_initial_rooms()
	_connect_signals()
	
	# Initial updates
	room_manager.update_room_visuals()
	elevator_manager.update_networks()


## Initialize all managers
func _initialize_managers() -> void:
	# Create managers
	room_manager = RoomManager.new(self, _matrix, shelter_map)
	add_child(room_manager)
	
	elevator_manager = ElevatorManager.new(self, _matrix, platform_container)
	add_child(elevator_manager)
	
	build_manager = BuildManager.new(_matrix, shelter_map, room_manager)
	add_child(build_manager)
	
	dweller_manager = DwellerManager.new(self, dweller_container)
	add_child(dweller_manager)


## Connect signals between managers and UI
func _connect_signals() -> void:
	GlobalSignal.add_listener("build_card_selected", _on_build_card_selected)
	
	room_manager.room_added.connect(_on_room_added)
	room_manager.room_removed.connect(_on_room_removed)
	
	build_manager.build_mode_enabled.connect(_on_build_mode_enabled)
	build_manager.build_mode_disabled.connect(_on_build_mode_disabled)


## Set up initial vault configuration
func _setup_initial_rooms() -> void:
	# Place the vault door
	var vault_door = VaultDoor.new()
	room_manager.add_room(vault_door, [Vector2(1, 0), Vector2(2, 0)])
	
	# Place two elevator shafts
	for y in range(2):
		var elevator = ElevatorShaft.new()
		room_manager.add_room(elevator, [Vector2(3, y)])
	
	# Place empty locations
	for x in _matrix.size.x:
		if _matrix._is_room_at(x, 0):
			continue
		
		var empty_location = EmptyLocation.new()
		room_manager.add_room(empty_location, [Vector2(x, 0)])


## Handle unhandled input events
func _unhandled_input(event) -> void:
	_remove_pointer()
	
	var ray_bodies = camera.screen_point_to_ray(null, false, true)
	var ray_areas = camera.screen_point_to_ray(null, true, false)
	var pos_on_plane = camera.get_mouse_position_on_plane()
	
	# Close room selector on click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		roomSelectorInterface.hide()
	
	# Handle area interactions (rooms)
	if ray_areas.has("collider"):
		_handle_room_interaction(event, ray_areas)
	
	# Handle dweller drag and drop
	_handle_dweller_interaction(event, ray_bodies, pos_on_plane)


## Handle room interaction (selection, building)
func _handle_room_interaction(event, ray_areas) -> void:
	var z = roundi((ray_areas.position.z + 1.5) / shelter_map.cell_size.z) * -1
	var y = roundi((ray_areas.position.y) / shelter_map.cell_size.y)
	y = _matrix.size.y - y - 1
	
	var collider_parent = ray_areas.collider.get_parent().get_parent()
	if collider_parent == shelter_map:
		return
	
	# Show pointer on valid rooms
	if _matrix._is_room_at(z, y):
		var room = _matrix.get_room_at(z, y)
		if room and not (room is EmptyLocation):
			_place_pointer(y, z)
	
	if event is InputEventMouseButton:
		var room = _matrix.get_room_at(z, y)
		
		# Show room selector
		if room and not (room is EmptyLocation) and roomSelectorInterface != null:
			roomSelectorInterface.show()
			roomSelectorInterface.bind(room)
		
		# Build mode placement
		if build_manager.is_build_mode_active and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if build_manager.build_room_at(z, y):
				room_manager.update_room_visuals()
				elevator_manager.update_networks()


## Handle dweller drag and drop
func _handle_dweller_interaction(event, ray_bodies, pos_on_plane) -> void:
	# Skip mouse wheel events
	if event is InputEventMouseButton and event.button_index in [
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
		MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT
	]:
		return
	
	# Start drag
	if event is InputEventMouseButton and event.is_pressed() and ray_bodies.has("collider"):
		if ray_bodies.collider is AnimatableBody3D:
			camera.body_drag_mode = true
			dweller_manager.select_dweller(ray_bodies.collider.get_parent())
	
	# End drag
	elif event is InputEventMouseButton and not event.is_pressed():
		if dweller_manager.selected_dweller:
			_handle_dweller_drop(pos_on_plane)
		
		camera.body_drag_mode = false
		dweller_manager.deselect_dweller()
		drag_body.hide()
	
	# Update drag visual
	if dweller_manager.selected_dweller and event is InputEventMouseMotion:
		drag_body.show()
		drag_body.position.z = pos_on_plane.z
		drag_body.position.y = pos_on_plane.y


## Handle dweller drop onto room
func _handle_dweller_drop(pos_on_plane: Vector3) -> void:
	var dweller = dweller_manager.selected_dweller
	if not dweller:
		return
	
	var z = roundi((pos_on_plane.z + 1) / shelter_map.cell_size.z) * -1
	var y = _matrix.size.y - roundi(pos_on_plane.y / shelter_map.cell_size.y) - 1
	
	var target_room = _matrix.get_room_at(z, y)
	
	# Don't drop on same room, elevator, or empty location
	if not target_room or target_room is ElevatorShaft or target_room is EmptyLocation:
		return
	
	if dweller.work and dweller.work.assigned_room == target_room:
		return
	
	# Assign to new room
	dweller_manager.move_dweller_to_room(dweller, target_room)


## Place a pointer on a room
func _place_pointer(y: int, z: int) -> void:
	var room = _matrix.get_room_at(z, y)
	if not room:
		return
	
	var r_positions = room.positions.duplicate()
	r_positions.sort_custom(_matrix._sort_postions)
	
	var first_position = r_positions[0]
	var coordinate = Vector3i(
		1, _matrix.size.y - first_position.y - 1, -first_position.x
	)
	
	var mesh = _pointer_meshes[0]
	if room.size == 2:
		mesh = _pointer_meshes[1]
	elif room.size == 3:
		mesh = _pointer_meshes[2]
	
	shelter_map.set_cell_item(coordinate, mesh.name)


## Remove all pointers
func _remove_pointer() -> void:
	for mesh in _pointer_meshes:
		var item_id = shelter_map._get_item_index(mesh.name)
		var cell = shelter_map._get_cell(item_id)
		
		if cell:
			shelter_map._remove_instance(cell)


## Handle build card selection
func _on_build_card_selected(selected_room: int) -> void:
	build_manager.enable_build_mode(selected_room)


## Handle room added
func _on_room_added(_room: RoomEntity) -> void:
	pass  # Additional logic if needed


## Handle room removed
func _on_room_removed(_room: RoomEntity) -> void:
	elevator_manager.update_networks()


## Handle build mode enabled
func _on_build_mode_enabled(_room_type: int) -> void:
	pass  # Additional UI feedback if needed


## Handle build mode disabled
func _on_build_mode_disabled() -> void:
	room_manager.update_room_visuals()
