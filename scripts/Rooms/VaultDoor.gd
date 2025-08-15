class_name VaultDoor extends Room

@onready var t_cooldown: Timer:
	get:
		return room_node.get_node("tCooldown")

var meshes = {2: MeshLink._meshes.VAULTDOOR}

var room_name: String = "Vault Door"
var is_open = false
var _asked_for_opening: bool = false
var _opening_callback: Array[Callable] = []

var animation_player: AnimationPlayer:
	get:
		return _get_animation_player()


func _constructor():
	max_size = 2
	destroyable = false

	for key in meshes:
		var el = meshes[key]

		var working_pool_param = WorkingPoolParameters.new()
		working_pool_param.append_positions(key, MeshLink.get_spots(el.name))

		working_spots = WorkingPool.new(working_pool_param)


func _process(_delta: float) -> void:
	if animation_player.is_playing():
		return

	if is_open:
		for callback in _opening_callback:
			callback.call()
		_opening_callback.clear()

	if is_open and _asked_for_opening:
		_asked_for_opening = false
		t_cooldown.start()

	if animation_player.is_playing():
		return

	if _asked_for_opening and !is_open:
		animation_player.play("open_door")
		await animation_player.animation_finished
		is_open = true

		t_cooldown.start()
	elif !_asked_for_opening and is_open and t_cooldown.is_stopped():
		_asked_for_opening = false
		is_open = false
		animation_player.play_backwards("open_door")


func _get_animation_player() -> AnimationPlayer:
	return room_node.get_node("AnimationPlayer")


func open_request(callback: Callable) -> void:
	_opening_callback.append(callback)
	_asked_for_opening = true
