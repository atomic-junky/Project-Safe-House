class_name DwellerEntity
extends "res://scripts/core/Entity.gd"

const Component = preload("res://scripts/components/Component.gd")

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
	component.entity = self
	component.initialize()
