class_name UpgradeComponent extends Component
## Component that manages room upgrades.
##
## This component handles room level progression, upgrade costs,
## and benefits from upgrades.


## Signal emitted when room is upgraded
signal upgraded(new_level: int)

## Signal emitted when room reaches max level
signal max_level_reached


## Current room level (1-3)
var room_level: int = 1

## Maximum level this room can reach
@export_range(1, 3) var max_level: int = 3

## Cost multiplier for each upgrade level
@export var upgrade_cost_multiplier: float = 2.0

## Base upgrade cost
@export var base_upgrade_cost: int = 100


## Check if room can be upgraded
func can_upgrade() -> bool:
	return room_level < max_level


## Get the cost to upgrade to the next level
func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0
	
	return int(base_upgrade_cost * pow(upgrade_cost_multiplier, room_level - 1))


## Upgrade the room to the next level
func upgrade() -> bool:
	if not can_upgrade():
		return false
	
	room_level += 1
	upgraded.emit(room_level)
	
	if room_level >= max_level:
		max_level_reached.emit()
	
	return true


## Get the production/efficiency bonus for current level
func get_level_bonus() -> float:
	# 0% bonus at level 1, 25% at level 2, 50% at level 3
	return (room_level - 1) * 0.25


## Get the capacity bonus for current level
func get_capacity_bonus() -> int:
	# +1 worker per level beyond 1
	return room_level - 1


## Reset room to level 1
func reset_level() -> void:
	room_level = 1
