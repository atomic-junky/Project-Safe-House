class_name ShelterCore

extends Node3D


@onready var shelter_map: AutoSceneMap = $AutoSceneMap
@onready var platform_container = $PlatformContainer
@onready var drag_body = $DragBody
@onready var dweller_container = $DwellerContainer

@onready var elevator_platform = preload("res://objects/map_scenes/shelter/ElevatorPlatform.tscn")

var _matrix = Matrix.new(14, 25)
var _selected_build_room = null
var _selected_dweller = null
var _elevator_networks = []


func _ready():
	GlobalSignal.add_listener("build_card_selected", _on_build_mode_enabled)
	
	# Place the vault door
	var _vault_door = VaultDoor.new()
	_matrix.add_room(_vault_door, [Vector2(1, 0), Vector2(2, 0)])
	
	# Place two elevators 
	for y in range(2):
		var _elevator = ElevatorShaft.new()
		_matrix.add_room(_elevator, [Vector2(3, y)])

	# Empty locations
	for x in _matrix.size.x:
		var _empty_location = EmptyLocation.new()
		if _matrix._is_room_at(x, 0):
			continue

		_matrix.add_room(_empty_location, [Vector2(x, 0)])

	_update_rooms()
	_update_elevator_networks()


func _input(event) -> void:
	_remove_pointer()

	var camera = $Camera
	var ray_bodies = camera.screen_point_to_ray(null, false, true)
	var ray_areas = camera.screen_point_to_ray(null, true, false)
	var pos_on_plane = camera.get_mouse_position_on_plane()

	if ray_areas.has("collider"):
		var z = roundi((ray_areas.position.z+1.5)/ shelter_map.cell_size.z) * -1
		var y = roundi((ray_areas.position.y)/ shelter_map.cell_size.y)
		y = _matrix.size.y - y - 1

		var collider_parent = ray_areas.collider.get_parent().get_parent()
		if collider_parent == shelter_map:
			return

		if _matrix._is_room_at(z, y):
			var room = _matrix.get_room_at(z, y)
			if room is Room and !room is EmptyLocation:
				_place_pointer(y, z)

		if _selected_build_room != null and event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				if not _is_a_build_location(z, y, _selected_build_room):
					return
			
				var _room = RoomPicker.pick(_selected_build_room).new()
				_matrix.add_room(_room, [Vector2(z, y)])

				_update_rooms()
				_update_elevator_networks()

				_selected_build_room = null
				return

	# Dweller Drag and Drop Handler
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		return

	if event is InputEventMouseButton and event.is_pressed() and ray_bodies.has("collider") and ray_bodies.collider is AnimatableBody3D:
		camera.body_drag_mode = true
		_selected_dweller = ray_bodies.collider.get_parent()
	elif event is InputEventMouseButton and !event.is_pressed():
		if _selected_dweller:
			var dweller_room = _selected_dweller.assigned_room
			var target_room = _matrix.get_room_at(
				roundi((pos_on_plane.z + 1)/ shelter_map.cell_size.z) * -1,
				_matrix.size.y - roundi(pos_on_plane.y/ shelter_map.cell_size.y) - 1
			)

			if not (dweller_room != null and dweller_room == target_room) and target_room != null:
				if not (target_room is ElevatorShaft or target_room is EmptyLocation):
					_selected_dweller.path_to_room(target_room)
				
		camera.body_drag_mode = false
		_selected_dweller = null
		drag_body.hide()
	
	if _selected_dweller != null and event is InputEventMouseMotion:
		drag_body.show()
		drag_body.position.z = pos_on_plane.z
		drag_body.position.y = pos_on_plane.y
		return


func _on_build_mode_enabled(selected_room) -> void:
	for y in _matrix.size.y:
		for z in _matrix.size.x:
			if not _is_a_build_location(z, y, selected_room):
				continue
			
			_place_build_location(y, z)
	
	_selected_build_room = selected_room


func _is_a_build_location(z, y, build_room) -> bool:
	var room = _matrix.get_room_at(z, y)
	if room != null or room is EmptyLocation:
		return false
		
	var prev_room = _matrix.get_room_at(z-1, y) if z > 0 else null
	var next_room = _matrix.get_room_at(z+1, y) if z < _matrix.size.x else null
	var top_room = _matrix.get_room_at(z, y-1) if y > 0 else null
	var bottom_room =_matrix.get_room_at(z, y+1) if y < _matrix.size.y else null
	
	# If the selected room is an elevator
	if build_room == RoomList.ELEVATOR:
		if (top_room != null and top_room is ElevatorShaft) or (bottom_room != null and bottom_room is ElevatorShaft):
			return true
	
	if prev_room != null or next_room != null:
		return true
	
	return false


func _update_rooms() -> void:
	shelter_map.clear()
	
	for y in range(_matrix.size.y):
		for z in range(_matrix.size.x):
			var room = _matrix.get_room_at_first_position(z, y)
			var _next_room = _matrix.get_room_at(z+1, y) if z < _matrix.size.y else null
			
			# Nothing
			if room == null or room is EmptyLocation:
				if not _matrix._is_room_at(z, y):
					_place_room(y, z, MeshLink._meshes.DIRT.name)
				continue

			if room.get_parent() != self:			
				add_child(room)
			_place_room(y, z, room.mesh.name, room)


func _update_elevator_networks() -> void:
	var new_networks = _get_elevator_networks()

	for platform: ElevatorPlatform in platform_container.get_children():
		var freeable = true
		for network in new_networks:
			if platform._current_elevator in network:
				freeable = false
				platform.network = network

		if freeable:
			platform.queue_free()


	for network in new_networks:
		var already_have_platform = false
		for platform: ElevatorPlatform in platform_container.get_children():
			if platform.network == network:
				already_have_platform = true

		var first_elevator: ElevatorShaft = network[0]

		if not already_have_platform:
			var new_platform = elevator_platform.instantiate()

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


func _get_elevator_networks() -> Array[Array]:
	var networks: Array[Array] = []
	var visited = []

	for x in range(_matrix.size.x):
		var network = []

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


func _place_room(y: int, z: int, mesh_name: String, room: Room = null) -> void:
	var coordinate = Vector3i(
		0, _matrix.size.y-y-1, -z
	)

	shelter_map.set_cell_item(coordinate, mesh_name)

	if room != null:
		room.room_node = shelter_map._get_cell_node(coordinate)


func _place_build_location(y: int, z: int, _size: int = 1):
	_place_room(y, z, MeshLink._meshes.BUILD_LOCATION.name)


func _remove_pointer():
	for mesh in [MeshLink._meshes.POINTER_1L, MeshLink._meshes.POINTER_2L, MeshLink._meshes.POINTER_3L]:
		var item_id = shelter_map._get_item_index(mesh.name)
		var cell = shelter_map._get_cell(item_id)

		if not cell:
			continue

		shelter_map._remove_instance(cell)


func _place_pointer(y: int, z: int):
	var room: Room = _matrix.get_room_at(z, y)
	if room == null:
		return
	
	var r_positions = room.positions
	r_positions.sort_custom(_matrix._sort_postions)

	var first_position = r_positions[0]

	var coordinate = Vector3i(
		1, _matrix.size.y-first_position.y-1, -first_position.x
	)

	var mesh = MeshLink._meshes.POINTER_1L
	match room.size:
		2:
			mesh = MeshLink._meshes.POINTER_2L
		3:
			mesh = MeshLink._meshes.POINTER_3L

	shelter_map.set_cell_item(coordinate, mesh.name)
	