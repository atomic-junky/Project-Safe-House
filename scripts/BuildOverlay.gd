extends Control
class_name BuildOverlay


@export var tabs_container: Control
@export var background_overlay: ColorRect


func _ready():
	GlobalSignal.add_listener("build_button_pressed", _on_build_button_pressed)
	GlobalSignal.add_listener("build_card_selected", _on_build_card_selected)
	
	_on_tab_bar_tab_changed(0)

func _on_build_button_pressed():
	background_overlay.show()
	show()

func _on_build_card_selected(_room):
	background_overlay.hide_all()

func _on_tab_bar_tab_changed(tab):
	for _tab in tabs_container.get_children():
		_tab.hide()
	tabs_container.get_child(tab).show()

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			return
		background_overlay.hide_all()
		Global.interface_mode = false
