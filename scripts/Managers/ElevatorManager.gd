class_name ElevatorManager extends Node
## Manager for elevator network management.
##
## This manager handles elevator shaft networks, platform management,
## and dweller elevator transport.


## Signal emitted when elevator networks are updated
signal networks_updated


## Reference to the matrix
var matrix: Matrix

## Reference to the shelter core
var shelter: Node3D

## Platform container node
var platform_container: Node

## Elevator platform scene
var elevator_platform_scene: PackedScene

## Current elevator networks
var elevator_networks: Array[Array] = []


## Initialize the elevator manager
func _init(shelter_node: Node3D, matrix_ref: Matrix, platform_cont: Node) -> void:
	shelter = shelter_node
	matrix = matrix_ref
	platform_container = platform_cont
	elevator_platform_scene = preload("res://objects/map_scenes/shelter/ElevatorPlatform.tscn")


## Update all elevator networks
func update_networks() -> void:
	if not matrix:
		return
	
	var new_networks = _get_elevator_networks()
	
	# Clean up platforms for removed elevators
	for platform: ElevatorPlatform in platform_container.get_children():
		var freeable = true
		for network in new_networks:
			if platform._current_elevator in network:
				freeable = false
				platform.network = network
		
		if freeable:
			platform.queue_free()
	
	# Create platforms for new networks
	for network in new_networks:
		var already_have_platform = false
		for platform: ElevatorPlatform in platform_container.get_children():
			if platform.network == network:
				already_have_platform = true
		
		if not already_have_platform:
			_create_platform_for_network(network)
	
	# Update platform references in elevator shafts
	for platform: ElevatorPlatform in platform_container.get_children():
		for network in new_networks:
			if platform.network != network:
				continue
			
			for elevator in network:
				elevator._platform = platform
				elevator.is_open = false
	
	elevator_networks = new_networks
	networks_updated.emit()


## Create a platform for an elevator network
func _create_platform_for_network(network: Array) -> void:
	if network.is_empty():
		return
	
	var first_elevator: ElevatorShaft = network[0]
	var new_platform = elevator_platform_scene.instantiate()
	
	platform_container.add_child(new_platform)
	new_platform.global_position = first_elevator.room_node.global_position
	new_platform.network = network


## Get all elevator networks in the vault
func _get_elevator_networks() -> Array[Array]:
	var networks: Array[Array] = []
	var visited = []
	
	for x in range(matrix.size.x):
		var network = []
		
		for y in range(matrix.size.y):
			var room = matrix.get_room_at(x, y)
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


## Get the network containing a specific elevator
func get_network_for_elevator(elevator: ElevatorShaft) -> Array:
	for network in elevator_networks:
		if elevator in network:
			return network
	return []
