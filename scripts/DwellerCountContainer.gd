extends HBoxContainer

## Manages dweller creation/destruction with ECS integration
## Maintains bidirectional mapping between Node3D and ECS entities
## Syncs position between Node and ECS each frame

var DwellerObject: PackedScene = preload("res://prefabs/dwellers/Dweller.tscn")

@export var shelter: Node3D
@export var dweller_count_label: Label

# Track mapping between ECS entities and scene nodes
var ecs_entity_to_node: Dictionary = {}  # entity_id -> Node3D
var node_to_ecs_entity: Dictionary = {}  # Node3D -> entity_id


func _ready() -> void:
	await shelter.ready
	await get_tree().process_frame  # Wait for ECSManager to initialize
	_initialize_existing_dwellers()
	update_dweller_count()


func _process(_delta: float) -> void:
	"""Each frame: sync positions from ECS to Node3D"""
	for entity_id in ecs_entity_to_node.keys():
		var node = ecs_entity_to_node[entity_id]
		var transform = ECSManager.get_component(entity_id, "Transform")

		if node and transform:
			# Sync position from ECS to Node
			node.global_position = transform.position


func _initialize_existing_dwellers() -> void:
	"""Initialize ECS entities for dwellers already in the scene."""
	var existing_dwellers = shelter.dweller_container.get_children()
	for dweller_node in existing_dwellers:
		if dweller_node is Dweller:
			# Create ECS entity for this dweller
			var entity = ECSManager.create_dweller()
			if entity:
				var transform = ECSManager.get_component(entity.id, "Transform")
				if transform:
					transform.position = dweller_node.global_position

				ecs_entity_to_node[entity.id] = dweller_node
				node_to_ecs_entity[dweller_node] = entity.id

				# Tell dweller its ECS entity ID
				dweller_node.ecs_entity_id = entity.id

				print("Initialized dweller to ECS entity %d" % entity.id)


func update_dweller_count() -> void:
	var count: int = shelter.dweller_container.get_child_count()
	dweller_count_label.text = str(count)


func _on_add_dweller_pressed() -> void:
	"""Create dweller - creates both Node (visual) and ECS entity (logic)."""
	# Create Node for visual representation
	var new_dweller_node = DwellerObject.instantiate()
	new_dweller_node.position = Vector3(-1, 47.095, -1)
	shelter.dweller_container.add_child(new_dweller_node)

	# Create ECS entity for gameplay logic
	var ecs_entity = ECSManager.create_dweller()
	if ecs_entity:
		# Link Node and ECS entity
		ecs_entity_to_node[ecs_entity.id] = new_dweller_node
		node_to_ecs_entity[new_dweller_node] = ecs_entity.id

		# Tell dweller its ECS entity ID
		new_dweller_node.ecs_entity_id = ecs_entity.id

		# Set initial position in ECS
		var transform = ECSManager.get_component(ecs_entity.id, "Transform")
		if transform:
			transform.position = new_dweller_node.global_position

		print("Created dweller - Node + ECS entity %d" % ecs_entity.id)

	update_dweller_count()


func _on_remove_dweller_pressed() -> void:
	"""Remove dweller - destroys both Node and ECS entity."""
	var dwellers = shelter.dweller_container.get_children()
	if len(dwellers) > 0:
		var dweller_node = dwellers[len(dwellers) - 1]

		# Destroy ECS entity
		if dweller_node in node_to_ecs_entity:
			var entity_id = node_to_ecs_entity[dweller_node]
			ECSManager.destroy_dweller(entity_id)
			ecs_entity_to_node.erase(entity_id)
			node_to_ecs_entity.erase(dweller_node)
			print("Destroyed dweller - removed ECS entity %d" % entity_id)

		# Destroy Node
		dweller_node.free()

	update_dweller_count()


func _on_main_ready() -> void:
	update_dweller_count()


func get_ecs_entity_for_node(dweller_node: Node3D) -> int:
	"""Get the ECS entity ID for a dweller Node."""
	return node_to_ecs_entity.get(dweller_node, -1)


## Utility: Get dweller Node for an ECS entity
func get_node_for_ecs_entity(entity_id: int) -> Variant:
	"""Get the Node associated with an ECS entity."""
	return ecs_entity_to_node.get(entity_id, null)


## Debug: Print all dweller mappings
func debug_print_dweller_mappings() -> void:
	print("\n=== Dweller Mappings ===")
	print("ECS Entities: %d" % ecs_entity_to_node.size())
	for entity_id in ecs_entity_to_node.keys():
		var node = ecs_entity_to_node[entity_id]
		print("  Entity %d -> Node %s" % [entity_id, node.name])
	print("Nodes: %d" % node_to_ecs_entity.size())
	for node in node_to_ecs_entity.keys():
		var entity_id = node_to_ecs_entity[node]
		print("  Node %s -> Entity %d" % [node.name, entity_id])
	print("=====================\n")
