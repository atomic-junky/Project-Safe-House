class_name VaultDoor extends AbstractRoom

var room_name: String = "Vault Door"
var is_open = false
var _asked_for_opening: bool = false
var _opening_callback: Array[Callable] = []
var _pending_open: bool = false
var _pending_close: bool = false

@onready var t_cooldown: Timer:
	get:
		return room_node.get_node("tCooldown")


func _constructor() -> void:
	type = GlobalRoomManager.RoomType.ROOM_VAULTDOOR
	max_size = 2
	destroyable = false


func _ready() -> void:
	# Bind animation and cooldown signals once the room node is available.
	call_deferred("_initialize_doors")


func _initialize_doors() -> void:
	var anim := _get_animation_player()
	if anim:
		if not anim.animation_finished.is_connected(_on_animation_finished):
			anim.animation_finished.connect(_on_animation_finished)

	var cooldown := t_cooldown
	if cooldown:
		if not cooldown.timeout.is_connected(_on_cooldown_timeout):
			cooldown.timeout.connect(_on_cooldown_timeout)


func open_request(callback: Callable) -> void:
	if !callback.is_null():
		_opening_callback.append(callback)

	_asked_for_opening = true

	# Door already open -> flush callbacks and extend cooldown.
	if is_open and !_pending_close:
		_flush_open_callbacks()
		_restart_cooldown()
		_asked_for_opening = false
		return

	# Interrupt closing if a new request arrives.
	if _pending_close:
		_pending_close = false
		_pending_open = true
		_play_open_animation()
		return

	# Already scheduled to open.
	if _pending_open:
		return

	_pending_open = true
	_play_open_animation()


func _play_open_animation() -> void:
	var anim := _get_animation_player()
	if anim == null:
		_pending_open = false
		return
	anim.play("open_door")


func _play_close_animation() -> void:
	var anim := _get_animation_player()
	if anim == null:
		_pending_close = false
		is_open = false
		return
	anim.play_backwards("open_door")


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != "open_door":
		return

	if _pending_open:
		_pending_open = false
		is_open = true
		_asked_for_opening = false
		_restart_cooldown()
		_flush_open_callbacks()
		return

	if _pending_close:
		_pending_close = false
		is_open = false
		if _asked_for_opening:
			_pending_open = true
			_asked_for_opening = false
			_play_open_animation()


func _on_cooldown_timeout() -> void:
	if !_pending_close and !_pending_open and is_open and !_asked_for_opening:
		_pending_close = true
		_play_close_animation()


func _restart_cooldown() -> void:
	var cooldown := t_cooldown
	if cooldown:
		cooldown.start()


func _flush_open_callbacks() -> void:
	if _opening_callback.is_empty():
		return
	for callback in _opening_callback:
		if callback.is_null():
			continue
		callback.call()
	_opening_callback.clear()


func _get_animation_player() -> AnimationPlayer:
	if room_node == null:
		return null
	return room_node.get_node_or_null("AnimationPlayer")
