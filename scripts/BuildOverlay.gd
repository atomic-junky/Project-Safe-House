class_name BuildOverlay
extends Control

const NO_SELECTION := GlobalRoomManager.RoomType.ROOM_OUTSIDE

@export var tabs_container: Control
@export var background_overlay: ColorRect



func _ready() -> void:
	SignalBus.build_button_pressed.connect(_on_build_button_pressed)
	SignalBus.build_card_selected.connect(_on_build_card_selected)

	_on_tab_bar_tab_changed(0)


func _exit_tree() -> void:
	if SignalBus.build_button_pressed.is_connected(_on_build_button_pressed):
		SignalBus.build_button_pressed.disconnect(_on_build_button_pressed)
	if SignalBus.build_card_selected.is_connected(_on_build_card_selected):
		SignalBus.build_card_selected.disconnect(_on_build_card_selected)


func _on_build_button_pressed() -> void:
	if Global.build_mode or is_visible():
		_disable_build_mode()
		return
	_open_overlay()


func _on_build_card_selected(_room: GlobalRoomManager.RoomType) -> void:
	background_overlay.hide_all()


func _on_tab_bar_tab_changed(tab: int) -> void:
	for _tab in tabs_container.get_children():
		_tab.hide()
	tabs_container.get_child(tab).show()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			return
		_disable_build_mode()


func _open_overlay() -> void:
	background_overlay.show()
	show()
	Global.interface_mode = true
	Global.build_mode = false


func _disable_build_mode() -> void:
	background_overlay.hide_all()
	Global.interface_mode = false
	Global.build_mode = false
	Global.build_room = NO_SELECTION
	SignalBus.build_mode_disabled.emit()
