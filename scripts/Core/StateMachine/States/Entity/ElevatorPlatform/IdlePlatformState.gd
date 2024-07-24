class_name EIdlePlatformState extends State


const TRAVEL_SPEED = 1.5

@export var running_state: ERunningState

var current_elevator: ElevatorShaft
var platform: ElevatorPlatform


func _enter(actor: Node) -> void:
	current_elevator = actor.map_path.prev_room

	platform = current_elevator._platform
	platform.request(actor.map_path.get_current_room())
