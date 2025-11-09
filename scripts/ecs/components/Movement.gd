class_name Movement
extends RefCounted

## Movement component - stores movement data only

var velocity: Vector3 = Vector3.ZERO
var acceleration: float = 5.0
var max_speed: float = 1.5
var is_moving: bool = false
var target_position: Vector3 = Vector3.ZERO
