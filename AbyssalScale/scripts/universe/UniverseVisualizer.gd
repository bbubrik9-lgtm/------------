extends Node3D
class_name UniverseVisualizer

@export var body_scene: PackedScene # Сцена сферы для планет
@export var star_scene: PackedScene # Сцена для звезды
@export var black_hole_scene: PackedScene # Сцена для черной дыры

var body_nodes_map: Dictionary = {} # Связь BodyData -> Node3D

func _ready():
	# Ждем пока UniverseManager сгенерирует данные
	if not UniverseManager.system_generated.is_connected(_on_system_generated):
		UniverseManager.system_generated.connect(_on_system_generated)
	
	# Если система уже сгенерирована (например при перезапуске)
	if UniverseManager.bodies.size() > 0:
		visualize_system()

func _on_system_generated():
	visualize_system()

func visualize_system():
	print("[UniverseVisualizer] Визуализация системы...")
	
	for body_data in UniverseManager.bodies:
		create_body_node(body_data)
	
	print("[UniverseVisualizer] Создано объектов: ", get_child_count())

func create_body_node(data: CelestialTypes.BodyData) -> Node3D:
	var node: Node3D
	
	# Выбор префаба в зависимости от типа
	match data.type:
		CelestialTypes.BodyType.BLACK_HOLE:
			node = _create_black_hole(data)
		CelestialTypes.BodyType.STAR_YELLOW, CelestialTypes.BodyType.NEUTRON_STAR:
			node = _create_star(data)
		_:
			node = _create_planet(data)
	
	if node:
		add_child(node)
		body_nodes_map[data.id] = node
		UniverseManager.body_nodes[data.id] = node
		
		# Установка начальной позиции
		_update_body_position(node, data, 0.0)
		
	return node

func _create_planet(data: CelestialTypes.BodyData) -> Node3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = data.name
	
	var sphere = SphereMesh.new()
	sphere.radius = data.radius
	sphere.height = data.radius * 2
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = data.color
	material.emission_enabled = false
	material.roughness = 0.8
	mesh_instance.surface_override_material = material
	
	mesh_instance.position = Vector3(data.distance_from_star, 0, 0)
	mesh_instance.scale = Vector3.ONE
	
	# Добавляем метаданные
	mesh_instance.set_meta("body_data", data)
	
	# Если есть кольца
	if data.has_rings:
		_add_rings(mesh_instance, data.radius)
	
	return mesh_instance

func _create_star(data: CelestialTypes.BodyData) -> Node3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = data.name + "_Star"
	
	var sphere = SphereMesh.new()
	sphere.radius = data.radius
	sphere.height = data.radius * 2
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = data.color
	material.emission_enabled = true
	material.emission = data.color
	material.emission_energy_multiplier = 2.0
	mesh_instance.surface_override_material = material
	
	mesh_instance.position = Vector3.ZERO
	mesh_instance.scale = Vector3.ONE
	
	return mesh_instance

func _create_black_hole(data: CelestialTypes.BodyData) -> Node3D:
	var root = Node3D.new()
	root.name = data.name
	
	# Черная сфера
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = data.radius
	sphere.height = data.radius * 2
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	material.emission_enabled = false
	mesh_instance.surface_override_material = material
	
	root.add_child(mesh_instance)
	
	# Аккреционный диск (упрощенно - торус)
	var disk = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.ring_radius = data.radius * 2.5
	torus.tube_radius = data.radius * 0.5
	disk.mesh = torus
	
	var disk_mat = StandardMaterial3D.new()
	disk_mat.albedo_color = Color(1.0, 0.5, 0.1)
	disk_mat.emission_enabled = true
	disk_mat.emission = Color(1.0, 0.3, 0.0)
	disk_mat.emission_energy_multiplier = 3.0
	disk.surface_override_material = disk_mat
	
	disk.rotation.x = PI / 2.0
	root.add_child(disk)
	
	root.position = Vector3(data.distance_from_star, 0, 0)
	
	return root

func _add_rings(parent: MeshInstance3D, planet_radius: float):
	var rings = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.ring_radius = planet_radius * 2.0
	torus.tube_radius = planet_radius * 0.2
	rings.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.7, 0.6, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rings.surface_override_material = mat
	
	rings.rotation.x = PI / 2.0
	parent.add_child(rings)

func _update_body_position(node: Node3D, data: CelestialTypes.BodyData, time: float):
	if data.orbital_period > 0 and data.distance_from_star > 0:
		var angle = (time / data.orbital_period) * TAU
		node.position.x = cos(angle) * data.distance_from_star
		node.position.z = sin(angle) * data.distance_from_star
	else:
		node.position = Vector3(data.distance_from_star, 0, 0)
	
	# Вращение вокруг оси
	node.rotation.y += data.rotation_speed * 0.01

func _process(delta):
	# Обновление орбит
	for body_data in UniverseManager.bodies:
		if body_nodes_map.has(body_data.id):
			var node = body_nodes_map[body_data.id] as Node3D
			UniverseManager.time_elapsed += delta
			_update_body_position(node, body_data, UniverseManager.time_elapsed)
