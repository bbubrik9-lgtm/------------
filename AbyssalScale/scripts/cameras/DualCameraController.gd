extends Node3D
class_name DualCameraController

@export var near_camera: Camera3D
@export var far_camera: Camera3D # Опционально, если нужна отдельная камера для далеких объектов
@export var zoom_sensitivity: float = 0.5
@export var max_zoom_fov: float = 10.0
@export var min_zoom_fov: float = 90.0
@export var shake_intensity: float = 0.2

var is_zooming: bool = false
var current_fov: float = 90.0
var target_fov: float = 90.0
var zoom_level: float = 0.0 # 0.0 - нет зума, 1.0 - макс зум

var base_transform: Transform3D
var shake_offset: Vector3 = Vector3.ZERO

func _ready():
	if near_camera:
		near_camera.current = true
		base_transform = near_camera.transform
	target_fov = min_zoom_fov

func _input(event):
	# Зум по правой кнопке мыши или клавише V
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_zooming = event.pressed
		_update_zoom_target()
	
	if event.is_action_pressed("ui_focus"): # Назначьте клавишу V на action "ui_focus" в Project Settings
		is_zooming = not is_zooming
		_update_zoom_target()

	# Колесико для изменения силы зума
	if is_zooming and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_fov = max(max_zoom_fov, target_fov - 5.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_fov = min(min_zoom_fov, target_fov + 5.0)

func _update_zoom_target():
	if is_zooming:
		target_fov = max_zoom_fov
	else:
		target_fov = min_zoom_fov

func _process(delta):
	# Плавное изменение FOV
	current_fov = lerp(current_fov, target_fov, delta * 8.0)
	zoom_level = 1.0 - ((current_fov - max_zoom_fov) / (min_zoom_fov - max_zoom_fov))
	
	if near_camera:
		near_camera.fov = current_fov
		
		# Эффект тряски при сильном зуме
		if zoom_level > 0.5:
			var shake_factor = (zoom_level - 0.5) * 2.0 * shake_intensity
			shake_offset = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			) * shake_factor * delta
			
			# Применяем тряску локально, не сбрасывая позицию
			near_camera.transform.origin = base_transform.origin + shake_offset
		else:
			shake_offset = Vector3.ZERO
			near_camera.transform.origin = base_transform.origin

func set_base_transform(new_transform: Transform3D):
	base_transform = new_transform
	if near_camera:
		near_camera.transform = base_transform
