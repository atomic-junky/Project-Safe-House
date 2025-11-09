class_name RoomEntity
extends Node3D

var id: String = UUID.v4()
var room_type_id: String = ""
var max_size: int = 3
var destroyable: bool = true
var room_level: int = 1
var positions: Array[Vector2] = []
var size: int:
	get:
		return max(positions.size(), 1)
var _matrix: Matrix = null

var _components: Array[Component] = []


func _ready() -> void:
	_register_child_components()
	set_process(true)


func _process(delta: float) -> void:
	for component: Component in _components:
		component.update(delta)


func attach_component(component: Component) -> void:
	if component == null:
		return
	if component.get_parent() != self:
		add_child(component)
	_register_component(component)


func has_component(component_script: Script) -> bool:
	return get_component(component_script) != null


func get_component(component_script: Script) -> Component:
	if component_script == null:
		return null
	for component: Component in _components:
		var script: Script = component.get_script()
		if script == null:
			continue
		if script == component_script:
			return component
	return null


func _exit_tree() -> void:
	for component: Component in _components:
		component.cleanup()
	_components.clear()


func _register_child_components() -> void:
	for child: Node in get_children():
		if child is Component:
			_register_component(child)


func _register_component(component: Component) -> void:
	if _components.has(component):
		return
	_components.append(component)
	component.initialize()


func set_matrix(matrix: Matrix) -> void:
	_matrix = matrix


func set_positions(values: Array[Vector2]) -> void:
	positions = values.duplicate()


func destroy() -> void:
	if _matrix != null:
		var matrix := _matrix
		_matrix = null
		matrix.remove_room(self)
	else:
		queue_free()


func upgrade() -> void:
	room_level += 1
