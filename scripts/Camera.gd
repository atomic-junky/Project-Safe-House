extends Camera3D


const DEBUG_SPEED = 0.5
const DRAG_SPEED = 0.0015

const MIN_ZOOM: float = 0.001
const MAX_ZOOM: float = 0.45
const ZOOM_INCREMENT: float = 0.025
const ZOOM_RATE: float = 10.0
const MIN_HORIZONTAL_SCROLL: float = 3.0
const MAX_HORIZONTAL_SCROLL: float = -34
const MIN_VERTICAL_SCROLL: float = 50
const MAX_VERTICAL_SCROLL: float = 0

var _target_zoom: float = 0.01

var _disabled: bool = false
var body_drag_mode: bool = false

func _init():
	position.x = 3.6
	position.z = -4.85
	position.y = 46.5

func _ready():
	await get_tree().create_timer(0.2).timeout
	
	_target_zoom = 0.2

func _input(event) -> void:
	if _disabled or body_drag_mode:
		return
	
	var build_overlay = get_tree().current_scene.get_node_or_null("BuildOverlay")
	# Zoom
	if (not build_overlay or not build_overlay.visible) and event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()
	
	# Drag
	if (not build_overlay or not build_overlay.visible) and event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_LEFT:
			position.z -= -event.relative.x * zoom() * 100 * DRAG_SPEED
			position.y -= -event.relative.y * zoom() * 100 * DRAG_SPEED

func zoom() -> float:
	return round(position.x)/100

func zoom_in() -> void:
	_target_zoom = max(_target_zoom - ZOOM_INCREMENT, MIN_ZOOM)
	set_physics_process(true)
	
func zoom_out() -> void:
	_target_zoom = min(_target_zoom + ZOOM_INCREMENT, MAX_ZOOM)
	set_physics_process(true)

func screen_point_to_ray(to = null, collide_with_areas: bool = true, collide_with_bodies: bool = true):
	var space = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	
	var from = project_ray_origin(mouse_pos)
	if to == null:
		to = from + project_ray_normal(mouse_pos) * 100
	
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = collide_with_areas
	ray_query.collide_with_bodies = collide_with_bodies
	return space.intersect_ray(ray_query)


func _physics_process(delta):
	var _zoom = lerp(
		zoom(),
		_target_zoom * 1,
		ZOOM_RATE * delta
	) * 100
	
	# TODO: Limit the camera in y and z axis

	position.x = _zoom

	var screensize = get_viewport().get_visible_rect().size
	var m_pos = get_viewport().get_mouse_position()
	var centered_m_pos = (m_pos - screensize / 2) / (screensize / 2)

	# Constrain the centered mouse position to the range [-1, 1]
	centered_m_pos.x = clamp(centered_m_pos.x, -1, 1)
	centered_m_pos.y = clamp(centered_m_pos.y, -1, 1)

	# Apply a quadratic function for smoother and more gradual tilt
	var tilt_x = centered_m_pos.y * abs(centered_m_pos.y)
	var tilt_y = centered_m_pos.x * abs(centered_m_pos.x)

	# Update the rotation degrees
	rotation_degrees.x = tilt_x * -3  # Adjust multiplier for desired tilt strength
	rotation_degrees.y = 90 + tilt_y * -3  # Adjust multiplier for desired tilt strength



func get_mouse_position_on_plane():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_dir = project_ray_normal(mouse_pos)
	var plane = Plane( 1, 0, 0, 0 )
	var pos_on_plane = plane.intersects_ray(ray_origin, ray_dir)
	return pos_on_plane

func disable() -> void:
	_disabled = true

func enable() -> void:
	_disabled = false
