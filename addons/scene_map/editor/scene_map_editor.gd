@tool
class_name SceneMapEditor extends Control

enum PaletteDisplayMode { THUMBNAIL, LIST }

enum InputAction { NONE, PAINT, ERASE }

enum MenuOption {
	PREVIOUS_LEVEL,
	NEXT_LEVEL,
	EDIT_AXIS_X,
	EDIT_AXIS_Y,
	EDIT_AXIS_Z,
	ROTATE_CLOCKWISE,
	ROTATE_COUNTER_CLOCKWISE,
	ROTATE_RESET
}

const SceneMap = preload("../scene_map.gd")
const ScenePalette = preload("../scene_palette.gd")
const ROTATE_STEP = PI / 4.0  # 45 degrees

var plugin: EditorPlugin
var scene_map: SceneMap
var cursor: Node3D
var cursor_origin: Vector3
var cursor_rotation: Basis
var edit_axis: int = Vector3.AXIS_Y
var edit_floor: int = 0
var edit_grid: MeshInstance3D
var selected_item_id: int = -1
var current_input_action: int = InputAction.NONE
var changed_items: Array = []
var display_mode: int = PaletteDisplayMode.THUMBNAIL
var search_text: String = ""

@onready var palette_list := $Palette as ItemList
@onready var no_palette_warning := $NoPaletteWarning as Label
@onready var floor_label := $Toolbar/FloorLabel as Label
@onready var floor_control := $Toolbar/FloorBox as SpinBox
@onready var menu := $Toolbar/MenuButton as MenuButton
@onready var search_box := $SearchBar/Search as LineEdit
@onready var thumbnail_button := $SearchBar/Thumbnail as Button
@onready var list_button := $SearchBar/List as Button


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	if edit_grid:
		edit_grid.queue_free()
		edit_grid = null

	if cursor:
		cursor.queue_free()
		cursor = null


func _ready() -> void:
	thumbnail_button.icon = EditorInterface.get_editor_theme().get_icon(
		"FileThumbnail", "EditorIcons"
	)
	list_button.icon = EditorInterface.get_editor_theme().get_icon("FileList", "EditorIcons")
	search_box.right_icon = EditorInterface.get_editor_theme().get_icon("Search", "EditorIcons")

	# Menu setup (can't be done in scene)
	var menu_popup := menu.get_popup()
	menu_popup.connect("id_pressed", Callable(_menu_option_selected))
	menu_popup.set_item_accelerator(menu_popup.get_item_index(MenuOption.NEXT_LEVEL), KEY_E)
	menu_popup.set_item_accelerator(menu_popup.get_item_index(MenuOption.PREVIOUS_LEVEL), KEY_Q)
	menu_popup.set_item_accelerator(menu_popup.get_item_index(MenuOption.EDIT_AXIS_X), KEY_X)
	menu_popup.set_item_accelerator(menu_popup.get_item_index(MenuOption.EDIT_AXIS_Y), KEY_Y)
	menu_popup.set_item_accelerator(menu_popup.get_item_index(MenuOption.EDIT_AXIS_Z), KEY_Z)
	menu_popup.set_item_accelerator(menu_popup.get_item_index(MenuOption.ROTATE_CLOCKWISE), KEY_D)
	menu_popup.set_item_accelerator(
		menu_popup.get_item_index(MenuOption.ROTATE_COUNTER_CLOCKWISE), KEY_A
	)
	menu_popup.set_item_accelerator(menu_popup.get_item_index(MenuOption.ROTATE_RESET), KEY_S)


func edit(p_scene_map: SceneMap) -> void:
	if scene_map:
		if scene_map.is_connected("palette_changed", Callable(_update_palette)):
			scene_map.disconnect("palette_changed", Callable(_update_palette))

		if scene_map.is_connected("cell_size_changed", Callable(_update_grid)):
			scene_map.disconnect("cell_size_changed", Callable(_update_grid))

		if scene_map.is_connected("cell_center_changed", Callable(_update_grid)):
			scene_map.disconnect("cell_center_changed", Callable(_update_grid))

	scene_map = p_scene_map

	if scene_map:
		if !scene_map.is_connected("palette_changed", Callable(_update_palette)):
			scene_map.connect("palette_changed", Callable(_update_palette))

		if !scene_map.is_connected("cell_size_changed", Callable(_update_grid)):
			scene_map.connect("cell_size_changed", Callable(_update_grid))

		if !scene_map.is_connected("cell_center_changed", Callable(_update_grid)):
			scene_map.connect("cell_center_changed", Callable(_update_grid))

		_update_palette(scene_map.palette)
	else:
		_update_palette(null)


func handle_spatial_input(camera: Camera3D, event: InputEvent) -> bool:
	if !scene_map || !scene_map.palette:
		return false

	var undo_redo := plugin.get_undo_redo()

	var click_event := event as InputEventMouseButton
	if click_event:
		if click_event.button_index == MOUSE_BUTTON_WHEEL_UP && Input.is_key_pressed(KEY_SHIFT):
			if click_event.pressed:
				floor_control.value += click_event.factor
			return true
		if click_event.button_index == MOUSE_BUTTON_WHEEL_DOWN && Input.is_key_pressed(KEY_SHIFT):
			if click_event.pressed:
				floor_control.value -= click_event.factor
			return true

		if click_event.pressed:
			if click_event.button_index == MOUSE_BUTTON_LEFT:
				current_input_action = InputAction.PAINT
			elif click_event.button_index == MOUSE_BUTTON_RIGHT:
				current_input_action = InputAction.ERASE
			else:
				return false

			return _handle_input(camera, click_event.position)
		if (
			(
				click_event.button_index == MOUSE_BUTTON_LEFT
				&& current_input_action == InputAction.PAINT
			)
			|| (
				click_event.button_index == MOUSE_BUTTON_RIGHT
				&& current_input_action == InputAction.ERASE
			)
		):
			if !changed_items.is_empty():
				var action := (
					"SceneMap Paint"
					if current_input_action == InputAction.PAINT
					else "SceneMap Erase"
				)
				undo_redo.create_action(action)

				for i in range(changed_items.size()):
					var item := changed_items[i] as ChangeItem
					undo_redo.add_do_method(
						scene_map,
						"set_cell_item",
						item.coordinates,
						item.new_item,
						item.new_orientation
					)

					item = changed_items[changed_items.size() - 1 - i] as ChangeItem
					undo_redo.add_undo_method(
						scene_map,
						"set_cell_item",
						item.coordinates,
						item.old_item,
						item.old_orientation
					)

				undo_redo.commit_action()

				changed_items = []
				current_input_action = InputAction.NONE
				return true

		current_input_action = InputAction.NONE

	var move_event := event as InputEventMouseMotion
	if move_event:
		return _handle_input(camera, move_event.position)

	return false


func _handle_input(camera: Camera3D, point: Vector2) -> bool:
	if !cursor:
		return false

	var frustum := camera.get_frustum()
	var from := camera.project_ray_origin(point)
	var normal := camera.project_ray_normal(point)

	# Convert from global space to the local space of the scene map.
	var to_local_transform = scene_map.global_transform.affine_inverse()
	from = to_local_transform * (from)
	normal = to_local_transform.basis * (normal).normalized()

	var plane := Plane()
	plane.normal[edit_axis] = 1.0
	plane.d = edit_floor * scene_map.cell_size[edit_axis]

	var hit := plane.intersects_segment(from, normal * camera.far)
	if !hit:
		return false

	# Make sure the point is still visible by the camera to avoid painting on
	# areas outside of the camera's view.
	for frustum_plane in frustum:
		var local_plane := to_local_transform * (frustum_plane) as Plane
		if local_plane.is_point_over(hit):
			return false

	var cell := Vector3()
	for i in range(3):
		if i == edit_axis:
			cell[i] = edit_floor
		else:
			cell[i] = floor(hit[i] / scene_map.cell_size[i])

	cursor_origin = scene_map.get_cell_position(cell)
	_update_cursor_transform()
	_update_edit_grid_transform()

	match current_input_action:
		InputAction.PAINT:
			var change := ChangeItem.new()
			change.coordinates = cell
			change.old_item = scene_map.get_cell_item_id(cell)
			change.old_orientation = scene_map.get_cell_item_orientation(cell)
			change.new_item = selected_item_id
			change.new_orientation = cursor_rotation.get_rotation_quaternion()
			changed_items.append(change)

			scene_map.set_cell_item(change.coordinates, change.new_item, change.new_orientation)
			return true
		InputAction.ERASE:
			var change := ChangeItem.new()
			change.coordinates = cell
			change.old_item = scene_map.get_cell_item_id(cell)
			change.old_orientation = scene_map.get_cell_item_orientation(cell)
			change.new_item = -1
			change.new_orientation = Quaternion.IDENTITY
			changed_items.append(change)

			scene_map.set_cell_item(change.coordinates, change.new_item, change.new_orientation)
			return true

	return false


func _update_cursor_transform() -> void:
	var transform := Transform3D(cursor_rotation)
	transform.origin = cursor_origin
	transform = scene_map.global_transform * transform

	if cursor:
		cursor.transform = transform


func _update_edit_grid_transform() -> void:
	var transform := Transform3D()
	transform.origin = cursor_origin
	transform = scene_map.global_transform * transform

	if edit_grid:
		edit_grid.transform = transform


func _update_cursor_instance() -> void:
	if cursor:
		cursor.queue_free()
		cursor = null

	if selected_item_id >= 0 && scene_map && scene_map.palette:
		var scene := scene_map.palette.get_item_scene(selected_item_id)
		if scene:
			cursor = scene.instantiate()
			cursor.name = "Cursor"
			self.add_child(cursor)

		_update_cursor_transform()


func _update_palette(palette: ScenePalette) -> void:
	var last_selected_id := selected_item_id

	palette_list.clear()

	if !palette:
		search_box.text = ""
		search_box.editable = false
		no_palette_warning.show()
		palette_list.hide()

		selected_item_id = -1
		_update_cursor_instance()
		_update_grid()
		return

	search_box.editable = true
	no_palette_warning.hide()
	palette_list.show()

	match display_mode:
		PaletteDisplayMode.THUMBNAIL:
			palette_list.max_columns = 0
			palette_list.icon_mode = ItemList.ICON_MODE_TOP
			palette_list.fixed_column_width = 64
			palette_list.fixed_icon_size = Vector2(64, 64)
		PaletteDisplayMode.LIST:
			palette_list.max_columns = 1
			palette_list.icon_mode = ItemList.ICON_MODE_LEFT
			palette_list.fixed_column_width = 0
			palette_list.fixed_icon_size = Vector2.ZERO

	var item_count = 0
	var selected_item_index := -1
	var previewer := plugin.get_editor_interface().get_resource_previewer()
	for item_index in palette.size():
		var name := palette.get_item_name(item_index)
		if !name || name.is_empty():
			name = "#%s" % item_count

		if !search_text.is_empty() && !search_text.is_subsequence_of(name):
			continue

		if last_selected_id == item_index:
			selected_item_index = item_count

		palette_list.add_item(name)
		palette_list.set_item_metadata(item_count, item_index)
		palette_list.set_item_icon(
			item_count, EditorInterface.get_editor_theme().get_icon("PackedScene", "EditorIcons")
		)

		var scene := palette.get_item_scene(item_index)
		if scene:
			previewer.queue_resource_preview(
				scene.resource_path, self, "_thumbnail_result", item_index
			)

		item_count = item_count + 1

	if selected_item_index >= 0:
		palette_list.select(selected_item_index)
		_item_selected(selected_item_index)
	elif selected_item_id >= 0:
		selected_item_id = -1
		_update_cursor_instance()
		_update_grid()


func _floor_changed(value: float) -> void:
	edit_floor = value


func _item_selected(index: int) -> void:
	var item_id := palette_list.get_item_metadata(index) as int

	if selected_item_id != item_id:
		selected_item_id = item_id
		_update_cursor_instance()
		_update_grid()


func _menu_option_selected(option_id: int) -> void:
	match option_id:
		MenuOption.PREVIOUS_LEVEL:
			floor_control.value -= 1
		MenuOption.NEXT_LEVEL:
			floor_control.value += 1
		MenuOption.EDIT_AXIS_X, MenuOption.EDIT_AXIS_Y, MenuOption.EDIT_AXIS_Z:
			var base_option := MenuOption.EDIT_AXIS_X as int
			var new_axis := option_id - base_option

			# Check the newly selected option
			for i in range(3):
				var idx := menu.get_popup().get_item_index(base_option + i)
				menu.get_popup().set_item_checked(idx, i == new_axis)

			# Update the text of the floor selector to match the current edit mode.
			var next_level_item := menu.get_popup().get_item_index(MenuOption.NEXT_LEVEL)
			var prev_level_item := menu.get_popup().get_item_index(MenuOption.PREVIOUS_LEVEL)

			if new_axis == Vector3.AXIS_Y:
				menu.get_popup().set_item_text(next_level_item, tr("Next Floor"))
				menu.get_popup().set_item_text(prev_level_item, tr("Previous Floor"))
				floor_label.text = tr("Floor:")
			else:
				menu.get_popup().set_item_text(next_level_item, tr("Next Plane"))
				menu.get_popup().set_item_text(prev_level_item, tr("Previous Plane"))
				floor_label.text = tr("Plane:")

			# Try to keep the cursor in the same location in the new axis
			edit_axis = new_axis
			floor_control.value = floor(cursor_origin[edit_axis] / scene_map.cell_size[edit_axis])

			_update_grid()
		MenuOption.ROTATE_CLOCKWISE, MenuOption.ROTATE_COUNTER_CLOCKWISE:
			var clockwise: bool = option_id == MenuOption.ROTATE_CLOCKWISE
			var axis := Vector3()
			axis[edit_axis] = 1.0

			cursor_rotation = cursor_rotation.rotated(
				axis, -ROTATE_STEP if clockwise else ROTATE_STEP
			)
			_update_cursor_transform()
		MenuOption.ROTATE_RESET:
			cursor_rotation = Basis.IDENTITY
			_update_cursor_transform()


func _set_display_mode(mode: int) -> void:
	if display_mode == mode:
		return

	display_mode = mode

	match display_mode:
		PaletteDisplayMode.THUMBNAIL:
			thumbnail_button.button_pressed = true
			list_button.button_pressed = false
		PaletteDisplayMode.LIST:
			thumbnail_button.button_pressed = false
			list_button.button_pressed = true

	_update_palette(scene_map.palette)


func _thumbnail_result(
	path: String, preview: Texture2D, small_preview: Texture2D, user_data: int
) -> void:
	if !preview:
		return

	for i in range(palette_list.get_item_count()):
		var item_id := palette_list.get_item_metadata(i) as int
		if item_id == user_data:
			palette_list.set_item_icon(i, preview)


func _search_text_changed(new_text: String) -> void:
	if search_text == new_text:
		return

	search_text = new_text.strip_edges() if new_text else ""
	_update_palette(scene_map.palette)


func _update_grid() -> void:
	if edit_grid:
		edit_grid.queue_free()
		edit_grid = null

	if (
		selected_item_id < 0
		|| !scene_map
		|| !scene_map.palette
		|| is_equal_approx(scene_map.cell_size[edit_axis], 0.0)
	):
		return

	var offset := Vector3()
	if scene_map.cell_center_x:
		offset.x -= 0.5
	if scene_map.cell_center_y:
		offset.y -= 0.5
	if scene_map.cell_center_z:
		offset.z -= 0.5
	offset *= scene_map.cell_size

	var grid_material := preload("grid_material.tres") as ShaderMaterial
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	surface_tool.set_material(grid_material)

	var radius := 64
	match edit_axis:
		Vector3.AXIS_X:
			for i in range(-radius, radius + 1, scene_map.cell_size.z):
				surface_tool.add_vertex(Vector3(0, -radius, i) + offset)
				surface_tool.add_vertex(Vector3(0, radius, i) + offset)
			for i in range(-radius, radius + 1, scene_map.cell_size.y):
				surface_tool.add_vertex(Vector3(0, i, -radius) + offset)
				surface_tool.add_vertex(Vector3(0, i, radius) + offset)
		Vector3.AXIS_Y:
			for i in range(-radius, radius + 1, scene_map.cell_size.z):
				surface_tool.add_vertex(Vector3(-radius, 0, i) + offset)
				surface_tool.add_vertex(Vector3(radius, 0, i) + offset)
			for i in range(-radius, radius + 1, scene_map.cell_size.x):
				surface_tool.add_vertex(Vector3(i, 0, -radius) + offset)
				surface_tool.add_vertex(Vector3(i, 0, radius) + offset)
		Vector3.AXIS_Z:
			for i in range(-radius, radius + 1, scene_map.cell_size.y):
				surface_tool.add_vertex(Vector3(-radius, i, 0) + offset)
				surface_tool.add_vertex(Vector3(radius, i, 0) + offset)
			for i in range(-radius, radius + 1, scene_map.cell_size.x):
				surface_tool.add_vertex(Vector3(i, -radius, 0) + offset)
				surface_tool.add_vertex(Vector3(i, radius, 0) + offset)

	var mesh := surface_tool.commit()
	edit_grid = MeshInstance3D.new()
	edit_grid.mesh = mesh
	edit_grid.layers = 1 << 25
	self.add_child(edit_grid)

	_update_edit_grid_transform()


class ChangeItem:
	var coordinates: Vector3
	var new_item: int
	var new_orientation: Quaternion
	var old_item: int
	var old_orientation: Quaternion
