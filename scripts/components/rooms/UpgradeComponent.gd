class_name UpgradeComponent
extends "res://scripts/components/Component.gd"

@export_range(0, 99) var max_level: int = 3
@export var upgrade_costs: Array[int] = []

var level: int = 1


func can_upgrade() -> bool:
	if level >= max_level:
		return false
	if level - 1 >= upgrade_costs.size():
		return true
	return upgrade_costs[level - 1] >= 0


func get_next_cost() -> int:
	if level - 1 >= upgrade_costs.size():
		return 0
	return upgrade_costs[level - 1]


func apply_upgrade() -> void:
	if not can_upgrade():
		return
	level += 1


func reset() -> void:
	level = 1
