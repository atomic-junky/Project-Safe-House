class_name Work
extends RefCounted

## Work component - stores work assignment data only

var assigned_room: AbstractRoom = null
var is_working: bool = false
var work_efficiency: float = 1.0
var slot_index: int = -1
