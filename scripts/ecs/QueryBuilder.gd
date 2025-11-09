class_name QueryBuilder
extends RefCounted

## Query builder for finding entities with specific components.
## Inspired by GECS - fluent API for queries.

var with_components: Array[String] = []
var without_components: Array[String] = []
var iterate_components: Array[String] = []


func with(component_name: String) -> QueryBuilder:
	"""Add a component that entities must have."""
	if component_name not in with_components:
		with_components.append(component_name)
	return self


func with_all(component_names: Array[String]) -> QueryBuilder:
	"""Add multiple components that entities must have."""
	for name: String in component_names:
		if name not in with_components:
			with_components.append(name)
	return self


func without(component_name: String) -> QueryBuilder:
	"""Add a component that entities must NOT have."""
	if component_name not in without_components:
		without_components.append(component_name)
	return self


func without_all(component_names: Array[String]) -> QueryBuilder:
	"""Add multiple components that entities must NOT have."""
	for name: String in component_names:
		if name not in without_components:
			without_components.append(name)
	return self


func iterate(component_names: Array[String]) -> QueryBuilder:
	"""Specify which components to iterate over in process()."""
	iterate_components = component_names.duplicate()
	return self


func build() -> Dictionary:
	"""Build the query into a dictionary."""
	return {"with": with_components, "without": without_components, "iterate": iterate_components}
