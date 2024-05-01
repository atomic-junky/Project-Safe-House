class_name ShelterCore

extends Node3D


@onready var shelter_map = $AutoSceneMap
@onready var dc_assigned = $DwellerContainer/Assigned
@onready var drag_body = $DragBody

var _matrix = Matrix.new(14, 25)
var _selected_build_room = null
var _selected_dweller = null


func _ready():
	GlobalSignal.add_listener("build_card_selected", _on_build_mode_enabled)
	
	# Place the vault door
	var _vault_door = VaultDoor.new()
	_matrix.add_room(_vault_door, [Vector2(1, 0), Vector2(2, 0)])
	
	# Place two elevators 
	for y in range(2):
		var _elevator = Elevator.new()
		_matrix.add_room(_elevator, [Vector2(3, y)])

	# Empty locations
	for x in _matrix.size.x:
		var _empty_location = EmptyLocation.new()
		if _matrix._is_room_at(x, 0):
			continue

		_matrix.add_room(_empty_location, [Vector2(x, 0)])
	
	
	_update_rooms()


func _input(event) -> void:
	var camera = $Camera
	var ray = camera.screen_point_to_ray()
	var pos_on_plane = camera.get_mouse_position_on_plane()

	if _selected_build_room != null and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if ray.has("collider"):
				var collider_parent = ray.collider.get_parent().get_parent()
				if collider_parent == shelter_map:
					return
				
				var z = roundi((ray.position.z+1.5)/ shelter_map.cell_size.z) * -1
				var y = roundi((ray.position.y)/ shelter_map.cell_size.y)
				y = _matrix.size.y - y - 1
				
				if not _is_a_build_location(z, y, _selected_build_room):
					return
				
				var _room = RoomPicker.pick(_selected_build_room).new()
				_matrix.add_room(_room, [Vector2(z, y)])
				_update_rooms()
				_selected_build_room = null
				return
	
	# Dweller Drag and Drop Handler
	if event.is_pressed() and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		return

	if event is InputEventMouseButton and event.is_pressed() and ray.has("collider") and ray.collider is AnimatableBody3D:
		camera.body_drag_mode = true
		_selected_dweller = ray.collider.get_parent()
	elif event is InputEventMouseButton and !event.is_pressed():
		if _selected_dweller:
			# FIXME: Not very accurate (sometimes it select neighbour rooms)
			var dweller_room = _selected_dweller.assigned_room
			var target_room = _matrix.get_room_at(
				roundi((pos_on_plane.z + 1)/ shelter_map.cell_size.z) * -1,
				_matrix.size.y - roundi(pos_on_plane.y/ shelter_map.cell_size.y) - 1
			)

			if not (dweller_room != null and dweller_room == target_room) and target_room != null:
				_selected_dweller.path_to_room(pos_on_plane)
				
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
		if (top_room != null and top_room is Elevator) or (bottom_room != null and bottom_room is Elevator):
			return true
	
	if prev_room != null or next_room != null:
		return true
	
	return false

func _update_rooms() -> void:
	shelter_map.clear()
	print(shelter_map._scene_map.get_child_count())
	
	for y in range(_matrix.size.y):
		for z in range(_matrix.size.x):
			var room = _matrix.get_room_at_first_position(z, y)
			var _next_room = _matrix.get_room_at(z+1, y) if z < _matrix.size.y else null
			
			# Nothing
			if room == null or room is EmptyLocation:
				if not _matrix._is_room_at(z, y):
					_place_room(y, z, MeshLink._meshes.DIRT.name)
				continue
			
			_place_room(y, z, room.mesh.name)


func _place_room(y: int, z: int, mesh_name: String) -> void:
	shelter_map.set_cell_item(Vector3i(
		0, _matrix.size.y-y-1, -z
	), mesh_name)


func _place_room_border(y: int, z: int, size: int) -> void:
	shelter_map.set_cell_item(Vector3i(
		1, _matrix.size.y-y-1, -z
	), 6+size)


func _place_build_location(y: int, z: int, _size: int = 1):
	_place_room(y, z, MeshLink._meshes.BUILD_LOCATION.name)
