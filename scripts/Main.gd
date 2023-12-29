extends Node3D


@onready var grid_map = $GridMap
@onready var matrix = []

# Dweller Container
@onready var dweller_container = $DwellerContainer
@onready var dc_on_hold = $DwellerContainer/OnHold
@onready var dc_assigned = $DwellerContainer/Assigned
@onready var dc_free = $DwellerContainer/Free

const VaultRoom = preload("res://scripts/VaultRoom.gd")
const Dweller = preload("res://assets/dwellers/Dweller.tscn")

# List of all rooms
var rooms = []

var build_room
var dragging: bool = false
var max_height: int
var max_width: int

const ray_length = 1000


func _ready() -> void:
	for y in range(25):
		matrix.append([])
		for x in range(10):
			var new_room = VaultRoom.new(RoomList.DIRT)
			rooms.append(new_room)
			matrix[y].append(weakref(new_room))
		
	# Base Rooms
	matrix[0][0].get_ref().type = RoomList.OUTSIDE
	matrix[0][1].get_ref().type = RoomList.VAULTDOOR
	matrix[0][2] = matrix[0][1]
	matrix[0][3].get_ref().type = RoomList.ELEVATOR
	
	max_height = matrix.size() - 1
	max_width = matrix[0].size() - 1
	
	update_rooms()
	
	$OmniLight3D.position.z = -(max_width/2)*$GridMap.cell_size.y
	$OmniLight3D.position.y = (max_height/2)*$GridMap.cell_size.x
	
func _input(event) -> void:
	if Global.interface_mode:
		return
	
	if not $"../BuildOverlay".visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var mouse_3d = $Camera.screen_point_to_ray()
			if mouse_3d.has("collider") and mouse_3d.collider == $GridMap:
				if not Global.build_mode:
					return
				
				var z = roundi(mouse_3d.position.z/ $GridMap.cell_size.z) * -1
				var y = roundi((mouse_3d.position.y)/ $GridMap.cell_size.y)
				
				y = max_height - y
				var room = matrix[y][z].get_ref()
				
				if room.type != RoomList.DIRT:
					return
					
				print(Global.build_room)
				
				var prev_room = matrix[y][z-1].get_ref() if z > 0 else null
				var next_room = matrix[y][z+1].get_ref() if z < max_width else null
				var top_room = matrix[y-1][z].get_ref() if y > 0 else null
				var bottom_room = matrix[y+1][z].get_ref() if y < max_height else null
				
				if Global.build_room == RoomList.ELEVATOR:
					if top_room and top_room.type == RoomList.ELEVATOR:
						matrix[y][z] = new_room(RoomList.ELEVATOR)
						Logger.info("New elevator (" + matrix[y][z].get_ref().id + ")")
					elif bottom_room and bottom_room.type == RoomList.ELEVATOR:
						matrix[y][z] = new_room(RoomList.ELEVATOR)
						Logger.info("New elevator (" + matrix[y][z].get_ref().id + ")")
					elif (prev_room and prev_room.type != RoomList.DIRT) \
					or (next_room and next_room.type != RoomList.DIRT):
						matrix[y][z] = new_room(Global.build_room)
						Logger.info("New elevator (" + matrix[y][z].get_ref().id + ")")
					else:
						return
				else:
					if prev_room and prev_room.type == Global.build_room and (z-3 >= 0 and matrix[y][z-3].get_ref().id != prev_room.id):
						matrix[y][z] = matrix[y][z-1]
						Logger.info("Extend room (" + matrix[y][z].get_ref().id + ") on the right")
					elif next_room and next_room.type == Global.build_room and (z-3 <= max_height and matrix[y][z+3].get_ref().id != next_room.id):
						matrix[y][z] = matrix[y][z+1]
						Logger.info("Extend room (" + matrix[y][z].get_ref().id + ") on the left")
					elif (prev_room and prev_room.type != RoomList.DIRT) \
					or (next_room and next_room.type != RoomList.DIRT):
						matrix[y][z] = new_room(Global.build_room)
						Logger.info("New room (" + matrix[y][z].get_ref().id + ")")
					else:
						return
					
				Global.build_mode = false
				update_rooms()
				remove_all_unused_rooms()
	
func update_rooms() -> void:
	for y in matrix.size():
		for z in matrix[y].size():
			var room = matrix[y][z].get_ref()
			var prev_room = matrix[y][z-1].get_ref() if z > 0 else null
			var next_room = matrix[y][z+1].get_ref() if z < max_width else null
			
			# Nothing
			if room.type == RoomList.NONE or room.type == RoomList.OUTSIDE:
				continue
			
			# VaultDoor
			# [] -
			if (not prev_room or prev_room.type != RoomList.VAULTDOOR) and (not next_room or next_room.type == RoomList.VAULTDOOR ):
				grid_map.set_cell_item(Vector3i(
					0, max_height-y, -z
				), 9)
					
			# Dirt
			if room.type == RoomList.DIRT:
				grid_map.set_cell_item(Vector3i(
					0, max_height-y, -z
				), 0)
				continue
			
			# Elevator
			if room.type == RoomList.ELEVATOR:
				grid_map.set_cell_item(Vector3i(
					0, max_height-y, -z
				), 2)
				grid_map.set_cell_item(Vector3i(
					1, max_height-y, -z
				), 6)
				continue
				
			
			# Room
			if room.type >= RoomList.LIVING_ROOM:
				# [] [] []
				if (not prev_room or prev_room.id != room.id) and (z+2 < max_width and matrix[y][z+2].get_ref().id == room.id):
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), 5)
					grid_map.set_cell_item(Vector3i(
						1, max_height-y, -z
					), 8)
				
				# [] []
				elif (not prev_room or prev_room.id != room.id) and (next_room and next_room.id == room.id):
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), 4)
					grid_map.set_cell_item(Vector3i(
						1, max_height-y, -z
					), 7)
				
				# []
				elif (not prev_room or prev_room.id != room.id) and (not next_room or next_room.id != room.id):
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), get_room_mesh(room.type, 1))
					grid_map.set_cell_item(Vector3i(
						1, max_height-y, -z
					), 6)
				
				elif prev_room and room.id == prev_room.id:
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), -1)
					
				if prev_room and prev_room.id == room.id:
					grid_map.set_cell_item(Vector3i(
						1, max_height-y, -z
					), -1)
					
				
				continue
	
func toggle_build_mode(room_type) -> void:
	update_rooms()
	var dirt = 1 if Global.build_mode else 0
	build_room = room_type
		
	for y in matrix.size():
		for z in matrix[y].size():
			var room = matrix[y][z].get_ref()
			
			if room.type != RoomList.DIRT:
				continue
				
			var prev_room = matrix[y][z-1].get_ref() if z > 0 else null
			var next_room = matrix[y][z+1].get_ref() if z < max_width else null
			var top_room = matrix[y-1][z].get_ref() if y > 0 else null
			var bottom_room = matrix[y+1][z].get_ref() if y < max_height else null
			
			# Elevator
			if room_type == RoomList.ELEVATOR:
				if next_room and next_room.type != RoomList.DIRT:
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), dirt)
				elif prev_room and prev_room.type != RoomList.DIRT:
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), dirt)
				elif top_room and top_room.type == RoomList.ELEVATOR:
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), dirt)
				elif bottom_room and bottom_room.type == RoomList.ELEVATOR:
					grid_map.set_cell_item(Vector3i(
						0, max_height-y, -z
					), dirt)
				continue
			
			# Non-elevator room
			if prev_room and prev_room.type != RoomList.DIRT:
				grid_map.set_cell_item(Vector3i(
					0, max_height-y, -z
				), dirt)
				continue
			elif next_room and next_room.type != RoomList.DIRT:
				grid_map.set_cell_item(Vector3i(
					0, max_height-y, -z
				), dirt)
				continue
	
func new_room(type) -> WeakRef:
	var _new_room = VaultRoom.new(type)
	rooms.append(_new_room)
	return weakref(_new_room)
	
func get_room_mesh(type, size) -> int:
	#if size == 1:
		#match type:
			#RoomList.POWER_GENERATOR:
				#return 3
			#RoomList.WATER_TREATMENT:
				#return 3
			#RoomList.DINER:
				#return 3
	return 3
	
func remove_all_unused_rooms() -> void:
	var id_list = []
	
	for y in matrix.size():
		for z in matrix[y].size():
			id_list.append(matrix[y][z].get_ref().id)
	
	for room in rooms:
		if not room.id in id_list:
			rooms.erase(room)
			Logger.info("Room (" + room.id + ") removed from the container")


func get_all_dwellers():
	var dwellers = []
	for sub_node in dweller_container.get_children():
		dwellers.append_array(sub_node.get_children())
	
	return dwellers
