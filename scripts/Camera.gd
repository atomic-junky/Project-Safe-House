extends Camera3D


@onready var drag_body = $"../DragBody"

const DEBUG_SPEED = 0.5
const DRAG_SPEED = 0.0007

const MIN_ZOOM: float = 0.035
const MAX_ZOOM: float = 0.5
const ZOOM_INCREMENT: float = 0.05
const ZOOM_RATE: float = 8.0
const MIN_HORIZONTAL_SCROLL: float = 6.0
const MAX_HORIZONTAL_SCROLL: float = -18.5

var _target_zoom: float = 0.01
var selected_body = null

func _init():
	position.x = 3.6
	position.z = -4.85
	position.y = 46.5

func _ready():
	await get_tree().create_timer(0.2).timeout
	
	_target_zoom = 0.2

func _input(event) -> void:
	var build_overlay = get_tree().current_scene.get_node("BuildOverlay")
	# Zoom
	if not build_overlay.visible and event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()
	
	var ray = screen_point_to_ray()
	if event is InputEventMouseButton and event.is_pressed() and ray.has("collider") and ray.collider is AnimatableBody3D:
		selected_body = ray.collider.get_parent()
	elif event is InputEventMouseButton and !event.is_pressed():
		if selected_body:
			var pos_on_plane = get_mouse_position_on_plane()
			selected_body.target_position_calculator(pos_on_plane)
		selected_body = null
		drag_body.hide()
	
	if selected_body != null and event is InputEventMouseMotion:
		drag_body.show()
		var pos_on_plane = get_mouse_position_on_plane()
		drag_body.position.z = pos_on_plane.z
		drag_body.position.y = pos_on_plane.y
		return
	
	# Drag
	if not build_overlay.visible and event is InputEventMouseMotion:
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
	var zoom_ratio = 1-((((zoom() - 0) * 1) / (MAX_ZOOM - 0)))+1 # It work a bit
	position.z = min(MIN_HORIZONTAL_SCROLL*zoom_ratio, max(MAX_HORIZONTAL_SCROLL*zoom_ratio, position.z))
	
	var zoom = lerp(
		zoom(),
		_target_zoom * 1,
		ZOOM_RATE * delta
	)
	
	position.x = zoom * 100


func get_mouse_position_on_plane():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_dir = project_ray_normal(mouse_pos)
	var plane = Plane( 1, 0, 0, 0 )
	var pos_on_plane = plane.intersects_ray(ray_origin, ray_dir)
	return pos_on_plane
