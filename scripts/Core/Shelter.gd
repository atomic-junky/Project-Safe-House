class_name Shelter extends Node3D

const WORKSPOT_ROOM_TYPES := [
	GlobalRoomManager.RoomType.ROOM_LIVING_ROOM,
	GlobalRoomManager.RoomType.ROOM_POWER_GENERATOR,
	GlobalRoomManager.RoomType.ROOM_DINER,
	GlobalRoomManager.RoomType.ROOM_WATER_TREATMENT
]

const NO_SELECTION := GlobalRoomManager.RoomType.ROOM_OUTSIDE

@export var room_selector_interface: PanelContainer = null

var _matrix: Matrix = Matrix.new(14, 25)
var _selected_build_room: GlobalRoomManager.RoomType = NO_SELECTION
var _selected_dweller: Dweller = null
var _elevator_networks: Array[Array] = []
var _build_locations: Array[Node3D] = []
var _raycast_debug_enabled: bool = false

@onready var shelter_map: AutoSceneMap = $AutoSceneMap
@onready var platform_container: Node = $PlatformContainer
@onready var drag_body: Sprite3D = %DragBody
@onready var dweller_container: Node = $DwellerContainer

@onready var elevator_platform: PackedScene = preload("res://prefabs/shelter/ElevatorPlatform.tscn")


func get_matrix() -> Matrix:
	return _matrix


func _ready() -> void:
	SignalBus.build_card_selected.connect(_on_build_mode_enabled)
	SignalBus.build_mode_disabled.connect(_on_build_mode_disabled)

	_matrix.room_removed.connect(_on_matrix_room_removed)

	# Place the vault door
	_matrix.add_room(VaultDoor.new(), [Vector2(1, 0), Vector2(2, 0)])

	# Place two elevators
	for y in range(2):
		_matrix.add_room(ElevatorShaft.new(), [Vector2(3, y)])

	# Empty locations
	for x: int in _matrix.size.x:
		if _matrix._is_room_at(x, 0):
			continue

		_matrix.add_room(EmptyLocation.new(), [Vector2(x, 0)])

	_update_rooms()
	_update_elevator_networks()

	var camera: ShelterCamera = $Camera
	camera.set_debug_raycast(_raycast_debug_enabled)


func _unhandled_input(event: InputEvent) -> void:
	_remove_pointer()

	var camera: ShelterCamera = $Camera
	if event is InputEventKey and event.is_pressed() and !event.is_echo():
		if event.keycode == KEY_F7:
			_raycast_debug_enabled = !_raycast_debug_enabled
			camera.set_debug_raycast(_raycast_debug_enabled)
			var state := "enabled" if _raycast_debug_enabled else "disabled"
			FSLogger.info("Raycast debug %s" % state)

	var ray_bodies: Dictionary = _pick_dweller_hit(camera)
	var ray_areas: Dictionary = camera.screen_point_to_ray(200, true, false, [], 0, "room-ray")
	var pos_on_plane: Vector3 = camera.get_mouse_position_on_plane()
	var map_cell_size: Vector3 = shelter_map.get_cell_size()
	var build_target: Dictionary = {}
	#print(ray_bodies)
	if _selected_build_room != NO_SELECTION:
		build_target = _get_build_target_under_cursor(camera)
		var build_attempt = (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.is_pressed()
		)
		if build_attempt and _try_place_room(build_target):
			return

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.is_pressed()
	):
		room_selector_interface.hide()

	if ray_areas.has("collider"):
		var z: int = roundi((ray_areas.position.z + 1.5) / map_cell_size.z) * -1
		var y: int = roundi((ray_areas.position.y) / map_cell_size.y)
		y = int(_matrix.size.y - y - 1)

		var collider_parent: Node3D = ray_areas.collider.get_parent().get_parent()
		if collider_parent == shelter_map:
			return

		if _matrix._is_room_at(z, y):
			var room: Node = _matrix.get_room_at(z, y)
			if room is AbstractRoom and !room is EmptyLocation:
				_place_pointer(y, z)

		if event is InputEventMouseButton:
			var room: Node = _matrix.get_room_at(z, y)
			if room is AbstractRoom and !room is EmptyLocation and room_selector_interface != null:
				room_selector_interface.show()
				room_selector_interface.bind(room)

	# Dweller Drag and Drop Handler
	if (
		event is InputEventMouseButton
		and (
			event.button_index
			in [
				MOUSE_BUTTON_WHEEL_UP,
				MOUSE_BUTTON_WHEEL_DOWN,
				MOUSE_BUTTON_WHEEL_LEFT,
				MOUSE_BUTTON_WHEEL_RIGHT
			]
		)
	):
		return

	if (
		event is InputEventMouseButton
		and event.is_pressed()
		and ray_bodies.has("collider")
		and ray_bodies.collider is AnimatableBody3D
	):
		camera.set_body_drag_mode(true)
		_selected_dweller = ray_bodies.collider.get_parent()
		if _raycast_debug_enabled:
			FSLogger.debug(
				"Selected dweller %s via collider %s" % [
					_selected_dweller.name if _selected_dweller != null else "<null>",
					ray_bodies.collider.name
			]
			)
		if _selected_dweller != null:
			_selected_dweller.cancel_travel()
		# Start drag in ECS Draggable component
		if _selected_dweller != null and _selected_dweller.ecs_entity_id >= 0:
			var draggable = ECSManager.get_component(_selected_dweller.ecs_entity_id, "Draggable")
			if draggable != null:
				draggable.is_being_dragged = true
				draggable.drag_start_position = pos_on_plane
				draggable.drag_current_position = pos_on_plane

	elif event is InputEventMouseButton and !event.is_pressed():
		if _selected_dweller:
			# End drag in ECS Draggable component
			var draggable = ECSManager.get_component(_selected_dweller.ecs_entity_id, "Draggable")
			if draggable != null:
				draggable.is_being_dragged = false
			
			# Get target room
			var target_room: AbstractRoom = _matrix.get_room_at(
				roundi((pos_on_plane.z + 1) / map_cell_size.z) * -1,
				_matrix.size.y - roundi(pos_on_plane.y / map_cell_size.y) - 1
			)

			# Process drag end - move dweller if valid target
			_process_dweller_drop(_selected_dweller, target_room)

		camera.set_body_drag_mode(false)
		_selected_dweller = null
		drag_body.hide()

	if _selected_dweller != null and event is InputEventMouseMotion:
		drag_body.show()
		drag_body.position.z = pos_on_plane.z
		drag_body.position.y = pos_on_plane.y

		# Update drag position in ECS Draggable component
		var draggable = ECSManager.get_component(_selected_dweller.ecs_entity_id, "Draggable")
		if draggable != null:
			draggable.drag_current_position = pos_on_plane
		return


func _on_build_mode_enabled(selected_room: GlobalRoomManager.RoomType) -> void:
	_selected_build_room = selected_room
	_refresh_build_locations()


func _is_a_build_location(z: int, y: int, build_room: GlobalRoomManager.RoomType) -> bool:
	if z < 0 or z >= int(_matrix.size.x) or y < 0 or y >= int(_matrix.size.y):
		return false

	# Prevent building on the surface row
	if y == 0:
		return false

	var room: Variant = _matrix.get_room_at(z, y)
	if room is EmptyLocation:
		room = null
	if room != null:
		return false

	var prev_room: Variant = _matrix.get_room_at(z - 1, y) if z > 0 else null
	if prev_room is EmptyLocation:
		prev_room = null
	var next_room: Variant = _matrix.get_room_at(z + 1, y) if z < _matrix.size.x else null
	if next_room is EmptyLocation:
		next_room = null
	var top_room: Variant = _matrix.get_room_at(z, y - 1) if y > 0 else null
	if top_room is EmptyLocation:
		top_room = null
	var bottom_room: Variant = _matrix.get_room_at(z, y + 1) if y < _matrix.size.y else null
	if bottom_room is EmptyLocation:
		bottom_room = null

	# If the selected room is an elevator
	if build_room == GlobalRoomManager.RoomType.ROOM_ELEVATOR:
		if (
			(top_room != null and top_room is ElevatorShaft)
			or (bottom_room != null and bottom_room is ElevatorShaft)
		):
			return true

	if prev_room != null or next_room != null:
		return true

	return false


func _update_rooms() -> void:
	# assert(false)
	# FIXME: It's too complex to get a room from either the room type or the class.
	# It must be more simple. And update rooms could be a lot more simpler.
	# A new room could only affet the postion where it is and the room nearby if they connects.
	_clear_build_locations()
	shelter_map.clear()

	for y in range(_matrix.size.y):
		for z in range(_matrix.size.x):
			var room: AbstractRoom = _matrix.get_room_at_first_position(z, y)

			# Nothing
			if room == null or room is EmptyLocation:
				if not _matrix._is_room_at(z, y):
					_place_room(y, z, GlobalRoomManager.RoomType.ROOM_DIRT)
				continue

			if room.get_parent() != self:
				add_child(room)
			_place_room(y, z, room.type, room.size, room)

	_refresh_build_locations()


func _update_elevator_networks() -> void:
	var new_networks: Array[Array] = _get_elevator_networks()

	for platform: ElevatorPlatform in platform_container.get_children():
		var freeable: bool = true
		for network: Array in new_networks:
			if platform._current_elevator in network:
				freeable = false
				platform.network = network

		if freeable:
			platform.queue_free()

	for network: Array in new_networks:
		var already_have_platform: bool = false
		for platform: ElevatorPlatform in platform_container.get_children():
			if platform.network == network:
				already_have_platform = true

		var first_elevator: ElevatorShaft = network[0]

		if not already_have_platform:
			var new_platform: Node3D = elevator_platform.instantiate()

			platform_container.add_child(new_platform)
			new_platform.global_position = first_elevator.room_node.global_position
			new_platform.network = network

	for platform: ElevatorPlatform in platform_container.get_children():
		for network in new_networks:
			if platform.network != network:
				continue

			for elevator in network:
				elevator._platform = platform
				elevator.is_open = false

	_elevator_networks = new_networks


func _clear_build_locations() -> void:
	for location: Node3D in _build_locations:
		if is_instance_valid(location):
			location.queue_free()
	_build_locations.clear()


func _refresh_build_locations() -> void:
	_clear_build_locations()
	if _selected_build_room == NO_SELECTION:
		return

	for y in range(_matrix.size.y):
		for z in range(_matrix.size.x):
			if not _is_a_build_location(z, y, _selected_build_room):
				continue
			_place_build_location(y, z)


func _get_elevator_networks() -> Array[Array]:
	var networks: Array[Array] = []
	var visited: Array = []

	for x in range(_matrix.size.x):
		var network: Array = []

		for y in range(_matrix.size.y):
			var room = _matrix.get_room_at(x, y)
			if not room is ElevatorShaft:
				if len(network) > 0:
					networks.append(network)
				network = []
				continue

			if room in visited:
				continue

			network.append(room)
			visited.append(room)

		if len(network) > 0:
			networks.append(network)

	return networks


func _place_room(
	y: int, z: int, room_type: GlobalRoomManager.RoomType, size: int = 1, room: AbstractRoom = null
) -> void:
	var coordinate: Vector3 = Vector3(0, _matrix.size.y - y - 1, -z)
	var palette_room_name: String = GlobalRoomManager.get_palette_room_name(room_type, size)

	shelter_map.set_cell_item(coordinate, palette_room_name)

	if room != null:
		room.room_node = shelter_map._get_cell_node(coordinate)
		_configure_work_spots(room)


func _place_build_location(y: int, z: int, _size: int = 1) -> void:
	var location := GlobalRoomManager.get_build_location()
	if location == null:
		return
	var coordinate: Vector3 = Vector3(0.1, _matrix.size.y - y - 1, -z)
	var instance := shelter_map.add_temporary_node(location, coordinate)
	if instance != null:
		instance.set_meta("matrix_coords", Vector2i(z, y))
		_build_locations.append(instance)


func _remove_pointer() -> void:
	# FIXME: Pointers could not use SceneMap
	# TODO: Rename Pointers
	#for mesh in [
	#MeshLink._meshes.POINTER_1L, MeshLink._meshes.POINTER_2L, MeshLink._meshes.POINTER_3L
	#]:
	#var item_id = shelter_map._get_item_index(mesh.name)
	#var cell = shelter_map._get_cell(item_id)
	#
	#if not cell:
	#continue
	#
	#shelter_map._remove_instance(cell)
	pass


func _place_pointer(_y: int, _z: int) -> void:
	# FIXME: Pointers could not use SceneMap
	# TODO: Rename Pointers
	#var room: AbstractRoom = _matrix.get_room_at(z, y)
	#if room == null:
	#return
	#
	#var r_positions = room.positions
	#r_positions.sort_custom(_matrix._sort_postions)
	#
	#var first_position = r_positions[0]
	#
	#var coordinate = Vector3i(1, _matrix.size.y - first_position.y - 1, -first_position.x)
	#
	#var mesh = MeshLink._meshes.POINTER_1L
	#match room.size:
	#2:
	#mesh = MeshLink._meshes.POINTER_2L
	#3:
	#mesh = MeshLink._meshes.POINTER_3L
	#
	#shelter_map.set_cell_item(coordinate, mesh.name)
	pass


func _on_matrix_room_removed() -> void:
	_update_rooms()
	_update_elevator_networks()


func _pick_dweller_hit(camera: ShelterCamera) -> Dictionary:
	var exclude: Array = []
	for _i in range(5):
		var hit: Dictionary = camera.screen_point_to_ray(200, false, true, exclude, 0, "dweller-ray")
		if hit.is_empty():
			return {}
		var collider: Variant = hit.get("collider")
		if collider == null:
			return {}
		if collider is AnimatableBody3D:
			return hit
		exclude.append(collider)
	return {}


func _process_dweller_drop(dweller: Dweller, target_room: AbstractRoom) -> void:
	"""Handle dweller drop - assign to room and start travel."""
	if dweller == null or target_room == null:
		return

	# Get current work assignment from ECS
	var work_component = ECSManager.get_component(dweller.ecs_entity_id, "Work")
	if work_component == null:
		return
	
	var current_room: AbstractRoom = work_component.assigned_room

	# Don't move if already in target room
	if current_room != null and current_room == target_room:
		return

	# Validate target room
	if target_room is ElevatorShaft or target_room is EmptyLocation:
		return

	if target_room.is_full():
		return

	# Assign to work (via Dweller public API which updates ECS)
	dweller.assign_to_work(target_room)

	# Request travel to room
	dweller.travel_to_room(target_room)



func _configure_work_spots(room: AbstractRoom) -> void:
	if room == null:
		return
	if !WORKSPOT_ROOM_TYPES.has(room.type):
		return
	var spots: Array = GlobalRoomManager.get_spots(room.type, room.size)
	if spots.is_empty():
		return
	var parameters := WorkingPoolParameters.new()
	parameters.append_positions(room.size, spots)
	room.working_spots = WorkingPool.new(parameters)


func _try_place_room(build_target: Dictionary) -> bool:
	if build_target.is_empty():
		return false

	var target_coords: Vector2i = build_target.coords
	if not _is_a_build_location(target_coords.x, target_coords.y, _selected_build_room):
		return false

	var room_script: GDScript = GlobalRoomManager.get_abstract_room(_selected_build_room)
	if room_script == null:
		return false

	var new_room: AbstractRoom = room_script.new()
	_matrix.add_room(new_room, [Vector2(target_coords.x, target_coords.y)])

	_update_rooms()
	_update_elevator_networks()

	return true


func _get_build_target_under_cursor(camera: Camera3D) -> Dictionary:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return {}

	var mouse_pos: Vector2 = viewport.get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var direction: Vector3 = camera.project_ray_normal(mouse_pos)
	var ray_length: float = 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * ray_length)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return {}

	var collider: Object = result.get("collider")
	if collider == null:
		return {}

	var coords: Vector2i

	if collider is Area3D:
		var parent_node: Node = (collider as Area3D).get_parent()
		if parent_node != null and parent_node.has_meta("matrix_coords"):
			coords = parent_node.get_meta("matrix_coords")
		else:
			return {}
	else:
		return {}

	return {"coords": coords, "collider": collider}


func _on_build_mode_disabled() -> void:
	_selected_build_room = NO_SELECTION
	_clear_build_locations()
