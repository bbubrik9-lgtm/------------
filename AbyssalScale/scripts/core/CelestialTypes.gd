extends RefCounted
class_name CelestialTypes

## Типы небесных тел для процедурной генерации
enum BodyType {
	STAR_YELLOW,      # Желтый карлик (как Солнце)
	STAR_RED_DWARF,   # Красный карлик
	STAR_BLUE_GIANT,  # Голубой гигант
	NEUTRON_STAR,     # Нейтронная звезда (Пульсар)
	BLACK_HOLE,       # Черная дыра
	GAS_GIANT,        # Газовый гигант
	ICE_GIANT,        # Ледяной гигант
	TERRESTRIAL,      # Землеподобная планета
	DESERT,           # Пустынная планета
	OCEANIC,          # Океаническая планета
	MOON_ROCKY,       # Каменный спутник
	MOON_ICE,         # Ледяной спутник
	ASTEROID,         # Астероид
	QUASAR            # Квазар (активное ядро галактики)
}

## Структура данных для одного небесного тела
class BodyData:
	var id: String
	var name: String
	var type: BodyType
	var mass: float          # Масса (относительная)
	var radius: float        # Радиус (в игровых единицах)
	var distance_from_star: float # Дистанция от центральной звезды
	var orbital_period: float # Период орбиты
	var rotation_speed: float # Скорость вращения вокруг оси
	var atmosphere_density: float # Плотность атмосферы (0-1)
	var temperature: float   # Средняя температура
	var color: Color         # Основной цвет
	var has_rings: bool      # Наличие колец
	var description: String  # Краткое описание
	var lore_entry: String   # Запись в лоре
	
	func _init():
		id = str(Time.get_unix_time_from_system()) + "_" + str(randi())
		description = "Объект класса " + str(BodyType.keys()[type])
		lore_entry = ""
