class_name ProductionComponent extends Component
## Component that manages resource production in a room.
##
## This component handles production of power, water, food, etc.
## Production rate is affected by dweller stats and room level.


## Signal emitted when production cycle completes
signal production_completed(resource_type: String, amount: float)

## Signal emitted when production starts
signal production_started(resource_type: String)


## Type of resource produced (power, water, food, etc.)
@export_enum("Power", "Water", "Food", "Stimpaks", "RadAway") var resource_type: String = "Power"

## Base production rate per cycle
@export var base_production_rate: float = 10.0

## Production cycle duration in seconds
@export var production_cycle_time: float = 5.0

## Whether production is currently active
var is_producing: bool = false

## Current production progress (0.0 to 1.0)
var production_progress: float = 0.0

## Production efficiency multiplier (based on dweller stats)
var efficiency_multiplier: float = 1.0

## Timer for production cycles
var _production_timer: Timer


## Initialize the production component
func _initialize() -> void:
	super._initialize()
	
	_production_timer = Timer.new()
	_production_timer.wait_time = production_cycle_time
	_production_timer.one_shot = false
	_production_timer.timeout.connect(_on_production_cycle_complete)
	add_child(_production_timer)


## Start production
func start_production() -> void:
	if not is_producing:
		is_producing = true
		_production_timer.start()
		production_started.emit(resource_type)


## Stop production
func stop_production() -> void:
	if is_producing:
		is_producing = false
		_production_timer.stop()
		production_progress = 0.0


## Update production efficiency based on dweller stats
func update_efficiency(dweller_stats: Array[float]) -> void:
	if dweller_stats.is_empty():
		efficiency_multiplier = 0.0
		stop_production()
		return
	
	# Calculate average stat value
	var avg_stat: float = 0.0
	for stat in dweller_stats:
		avg_stat += stat
	avg_stat /= float(dweller_stats.size())
	
	# Efficiency ranges from 0.5 (stat=1) to 2.0 (stat=10)
	efficiency_multiplier = 0.5 + (avg_stat / 10.0) * 1.5


## Get the current production amount for this cycle
func get_production_amount() -> float:
	return base_production_rate * efficiency_multiplier


## Update production progress
func _update(delta: float) -> void:
	if is_producing:
		production_progress = 1.0 - (_production_timer.time_left / production_cycle_time)


## Handle production cycle completion
func _on_production_cycle_complete() -> void:
	var amount: float = get_production_amount()
	production_completed.emit(resource_type, amount)
	production_progress = 0.0


## Clean up timers
func _cleanup() -> void:
	if _production_timer:
		_production_timer.queue_free()
