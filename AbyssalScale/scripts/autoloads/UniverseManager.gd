extends Node
class_name UniverseManagerClass

## Сигналы для уведомления других систем
signal system_generated()
signal body_scanned(body_data: CelestialTypes.BodyData)
signal anomaly_detected(location: Vector3, type: String)

const MAX_BODIES := 60
const SCALE_FACTOR := 1000000.0 # Масштаб для реальных физических величин

var bodies: Array[CelestialTypes.BodyData] = []
var body_nodes: Dictionary = {} # Связь ID -> Node3D
var star_position: Vector3 = Vector3.ZERO
var time_elapsed: float = 0.0

func _ready():
	generate_solar_system()

## Основная функция генерации системы
func generate_solar_system():
	bodies.clear()
	body_nodes.clear()
	print("[UniverseManager] Начало генерации глубокого космоса...")
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("AbyssalScaleDeepSpace")
	
	# 1. Центральная звезда
	var star = CelestialTypes.BodyData.new()
	star.name = "Sol-Prime"
	star.type = CelestialTypes.BodyType.STAR_YELLOW
	star.mass = 1.989e30 / SCALE_FACTOR
	star.radius = 15.0 # Игровой радиус для визуализации
	star.distance_from_star = 0.0
	star.orbital_period = 0.0
	star.color = Color(1.0, 0.95, 0.8)
	star.description = "Главная звезда системы. Источник жизни и радиации."
	add_body(star)
	
	var current_distance = 40.0 # Начальная дистанция для первой планеты
	
	# 2. Генерация планет и поясов (цикл до 50+ объектов)
	for i in range(1, 12): # 11 основных орбит
		var planet_type = _determine_planet_type(i, rng)
		var planet = CelestialTypes.BodyData.new()
		
		planet.type = planet_type
		planet.name = _generate_name(planet_type, i, rng)
		planet.distance_from_star = current_distance + rng.randf_range(5.0, 15.0)
		planet.radius = _get_radius_for_type(planet_type, rng)
		planet.mass = planet.radius * rng.randf_range(0.8, 1.5)
		planet.orbital_period = sqrt(pow(planet.distance_from_star, 3)) * 0.5
		planet.rotation_speed = rng.randf_range(0.02, 0.2)
		planet.atmosphere_density = _get_atmosphere_for_type(planet_type, rng)
		planet.temperature = 2500.0 / sqrt(planet.distance_from_star + 10.0)
		planet.color = _get_color_for_type(planet_type, rng)
		planet.has_rings = (planet.type == CelestialTypes.BodyType.GAS_GIANT or planet.type == CelestialTypes.BodyType.ICE_GIANT) and rng.randf() > 0.3
		
		add_body(planet)
		
		# 3. Генерация спутников для газовых гигантов и крупных планет
		if planet.type == CelestialTypes.BodyType.GAS_GIANT or planet.type == CelestialTypes.BodyType.ICE_GIANT:
			var moons_count = rng.randi_range(3, 8)
			for m in range(moons_count):
				var moon = CelestialTypes.BodyData.new()
				moon.type = CelestialTypes.BodyType.MOON_ICE if rng.randf() > 0.5 else CelestialTypes.BodyType.MOON_ROCKY
				moon.name = planet.name + "-Moon-" + str(m)
				moon.distance_from_star = planet.distance_from_star # Упрощенно: считаем от звезды, но визуально будут вокруг планеты
				moon.radius = rng.randf_range(0.8, 2.0)
				moon.mass = moon.radius * 0.1
				moon.orbital_period = planet.orbital_period / (m + 2)
				moon.color = _get_color_for_type(moon.type, rng)
				moon.description = "Спутник планеты " + planet.name
				add_body(moon)
		
		current_distance += planet.radius * 3.0 + rng.randf_range(10.0, 30.0)
	
	# 4. Добавление экзотических объектов на окраинах
	var black_hole = CelestialTypes.BodyData.new()
	black_hole.name = "The Maw"
	black_hole.type = CelestialTypes.BodyType.BLACK_HOLE
	black_hole.distance_from_star = current_distance + 200.0
	black_hole.radius = 25.0
	black_hole.mass = 50000.0
	black_hole.color = Color(0.0, 0.0, 0.0)
	black_hole.description = "Гравитационная сингулярность. Избегайте горизонта событий."
	add_body(black_hole)
	
	var neutron = CelestialTypes.BodyData.new()
	neutron.name = "Pulsar-X"
	neutron.type = CelestialTypes.BodyType.NEUTRON_STAR
	neutron.distance_from_star = current_distance + 100.0
	neutron.radius = 5.0
	neutron.mass = 10000.0
	neutron.color = Color(0.5, 0.8, 1.0)
	neutron.description = "Быстровращающаяся нейтронная звезда. Высокий уровень радиации."
	add_body(neutron)
	
	print("[UniverseManager] Генерация завершена. Всего тел: ", bodies.size())
	emit_signal("system_generated")

## Вспомогательные функции генерации
func _determine_planet_type(index: int, rng: RandomNumberGenerator) -> CelestialTypes.BodyType:
	if index == 1: return CelestialTypes.BodyType.DESERT
	if index == 2: return CelestialTypes.BodyType.TERRESTRIAL
	if index >= 3 and index <= 5: return CelestialTypes.BodyType.GAS_GIANT if rng.randf() > 0.4 else CelestialTypes.BodyType.ICE_GIANT
	return CelestialTypes.BodyType.ICE_GIANT

func _generate_name(type: CelestialTypes.BodyType, index: int, rng: RandomNumberGenerator) -> String:
	var prefixes = ["Kepler", "Proxima", "Alpha", "Beta", "Nova", "Void", "Dark"]
	var suffixes = ["Prime", "Major", "Minor", "X", "Zeta", "Null"]
	return prefixes[rng.randi() % prefixes.size()] + "-" + suffixes[rng.randi() % suffixes.size()] + "-" + str(index)

func _get_radius_for_type(type: CelestialTypes.BodyType, rng: RandomNumberGenerator) -> float:
	match type:
		CelestialTypes.BodyType.GAS_GIANT: return rng.randf_range(8.0, 15.0)
		CelestialTypes.BodyType.ICE_GIANT: return rng.randf_range(6.0, 10.0)
		CelestialTypes.BodyType.TERRESTRIAL: return rng.randf_range(2.0, 4.0)
		CelestialTypes.BodyType.DESERT: return rng.randf_range(2.0, 3.5)
		CelestialTypes.BodyType.MOON_ROCKY, CelestialTypes.BodyType.MOON_ICE: return rng.randf_range(0.5, 1.5)
		_: return rng.randf_range(3.0, 6.0)

func _get_atmosphere_for_type(type: CelestialTypes.BodyType, rng: RandomNumberGenerator) -> float:
	if type == CelestialTypes.BodyType.MOON_ROCKY or type == CelestialTypes.BodyType.ASTEROID: return 0.0
	if type == CelestialTypes.BodyType.GAS_GIANT: return 1.0
	return rng.randf_range(0.1, 0.9)

func _get_color_for_type(type: CelestialTypes.BodyType, rng: RandomNumberGenerator) -> Color:
	match type:
		CelestialTypes.BodyType.STAR_YELLOW: return Color(1.0, 0.95, 0.8)
		CelestialTypes.BodyType.GAS_GIANT: return Color(rng.randf_range(0.8, 1.0), rng.randf_range(0.6, 0.8), rng.randf_range(0.4, 0.6))
		CelestialTypes.BodyType.TERRESTRIAL: return Color(0.2, 0.7, 0.3)
		CelestialTypes.BodyType.DESERT: return Color(0.8, 0.6, 0.3)
		CelestialTypes.BodyType.ICE_GIANT: return Color(0.4, 0.6, 1.0)
		CelestialTypes.BodyType.MOON_ROCKY: return Color(0.5, 0.5, 0.5)
		CelestialTypes.BodyType.MOON_ICE: return Color(0.8, 0.9, 1.0)
		CelestialTypes.BodyType.BLACK_HOLE: return Color(0.0, 0.0, 0.0)
		CelestialTypes.BodyType.NEUTRON_STAR: return Color(0.5, 0.8, 1.0)
		_: return Color.WHITE

func add_body(data: CelestialTypes.BodyData):
	bodies.append(data)

func get_body_by_id(id: String) -> CelestialTypes.BodyData:
	for b in bodies:
		if b.id == id:
			return b
	return null

## Обновление позиций (вызывается из основного цикла игры)
func update_orbits(delta: float):
	time_elapsed += delta
	for i in range(bodies.size()):
		var body = bodies[i]
		if body.orbital_period > 0 and body.distance_from_star > 0:
			# Простая круговая орбита для демонстрации
			var angle = (time_elapsed / body.orbital_period) * TAU
			# Здесь должна быть логика обновления позиций нод, привязанных к этим данным
			# Но сам UniverseManager хранит только данные. Визуал обновляется в сцене.
