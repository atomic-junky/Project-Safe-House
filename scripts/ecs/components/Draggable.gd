class_name Draggable
extends RefCounted

## Draggable component - stores drag state only

var is_draggable: bool = true
var is_being_dragged: bool = false
var drag_start_position: Vector3 = Vector3.ZERO
var drag_current_position: Vector3 = Vector3.ZERO
