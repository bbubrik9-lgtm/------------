extends CharacterBody3D
class_name PlayerController

@export_group("Movement")
@export var move_acceleration: float = 15.0
@export var move_drag: float = 5.0
@export var sprint_multiplier: float = 2.0
@export var max_speed: float = 10.0

@export_group("Grabbing")
@export var grab_range: float = 2.5
@export var grab_force: float = 20.0

@export_group("Survival")
@export var max_oxygen: float = 100.0
@export var oxygen_depletion_rate: float = 2.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var grab_raycast: RayCast3D = $GrabRaycast # Настройте RayCast3D вперед от игрока

var is_grabbing: bool = false
var grab_target: Node3D = null
var oxygen: float = 100.0
var input_vector: Vector3 = Vector3.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	oxygen = max_oxygen

func _input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		# Вращение камеры
		rotate_y(-event.relative.x * 0.002)
		camera_pivot.rotate_x(-event.relative.y * 0.002)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/2, PI/2)
	
	# Захват поручней (ЛКМ или E)
	if event.is_action_pressed("ui_accept"): 
		toggle_grab()
	
	# Сброс захвата (R)
	if event.is_action_pressed("ui_home"):
		release_grab()

func _physics_process(delta):
	handle_survival(delta)
	
	if is_grabbing:
		handle_grabbing(delta)
	else:
		handle_flight(delta)
	
	move_and_slide()

func handle_flight(delta):
	# Получение ввода
	input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var up_input = Input.get_action_strength("move_up")
	var down_input = Input.get_action_strength("move_down")
	var sprint = Input.is_key_pressed(KEY_SHIFT)
	
	# Формирование вектора движения в локальном пространстве
	var direction = Vector3.ZERO
	direction.x = input_vector.x
	direction.z = input_vector.y
	direction.y = up_input - down_input
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		
		# Преобразование в глобальное направление с учетом поворота игрока
		var global_direction = transform.basis * direction
		if sprint:
			global_direction *= sprint_multiplier
		
		# Применение ускорения
		velocity += global_direction * move_acceleration * delta
		velocity = velocity.limit_length(max_speed * (sprint_multiplier if sprint else 1.0))
	else:
		# Инерция (затухание)
		velocity = velocity.lerp(Vector3.ZERO, move_drag * delta)

func handle_grabbing(delta):
	if grab_target:
		# Притягивание к точке захвата
		var target_pos = grab_target.global_position
		var dist = global_position.distance_to(target_pos)
		
		if dist > 0.1:
			velocity = (target_pos - global_position).normalized() * grab_force
		else:
			velocity = Vector3.ZERO
		
		# Ориентация игрока по поручню (опционально)
		# look_at(grab_target.global_position)

func toggle_grab():
	if is_grabbing:
		release_grab()
	else:
		attempt_grab()

func attempt_grab():
	grab_raycast.force_raycast_update()
	if grab_raycast.is_colliding():
		var collider = grab_raycast.get_collider()
		if collider.is_in_group("grabbable"):
			grab_target = collider
			is_grabbing = true
			print("Захват выполнен!")

func release_grab():
	is_grabbing = false
	grab_target = null
	print("Захват сброшен")

func handle_survival(delta):
	if oxygen > 0:
		oxygen -= oxygen_depletion_rate * delta
	else:
		# Логика удушья (урон здоровью)
		pass
