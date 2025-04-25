extends Node2D

@onready var generated_map = $GeneratedMap
@onready var player = $Node2D/Knight
@onready var little_orc = preload("res://LittleOrc/little_orc.tscn")
@onready var big_orc = preload("res://BIgOrc/big_orc.tscn")
@onready var mini_demon = preload("res://miniDemon/mini_demon.tscn")
@onready var slug = preload("res://SLug/Slug.tscn")
@onready var TorchScene = preload("res://Torch/torch.tscn")

@export var box_scene: PackedScene
var tile_size = 16

const DEBUG_ENABLED := true

var isFirstRoom = true
var lastPosition = null

const LAYER = 0
const DUNGEON_CELL_ID = 0

var rng := RandomNumberGenerator.new()

var max_romm_attemts := 7
var debug_nodes : Array[Node2D] = []

var ROOM_SIZE = Vector2i(21, 21)
const ROOM_SPACING = 15

var rooms : Array[Room] = []
var coridors := {}
var entrance: Vector2i
var exit: Vector2i

var enemy_spawn_weights = {
	"LittleOrc": 10,
	"BigOrc": 2,
	"MiniDemon": 6,
	"Slug": 4
}
var max_enemies_per_room = 10
var min_enemy_distance := 5
var spawned_enemies := []





func _ready():
	clear_debug()
	generated_map.clear()
	generate_map()
	rng.randomize()


func _input(event):
	if Input.is_action_just_pressed("generated_map"):
		isFirstRoom = true
		clear_debug()
		clear_spawned_enemies()
		clear_torches()
		clear_boxes()
		generated_map.clear()
		generate_map()


func generate_map():
	rooms = []
	for _i in range(max_romm_attemts):
		var room = generate_random_room()
		if room is Room:
			rooms.append(room)
			place_room(room)
			if room.room_size.x != 11:
				spawn_enemies_in_room(room)
				
	
	build_coridors(rooms)
	generate_entrance(rooms)
	generate_exit(rooms)


func generate_entrance(rooms: Array[Room]):
	for room in rooms:
		if room.room_size == Vector2i(11, 11):
			var entrance_cell = room.center
			var tile_size = 16 
			var entrance_pixel_pos = entrance_cell
			
			player.global_position = entrance_pixel_pos +  Vector2i(5, 6)*tile_size
		
			entrance = entrance_cell
			return

	
func generate_exit(rooms: Array[Room]):
	var farthest_room := rooms[0]
	var max_distance := 0.0
	
	for room in rooms:
		var distance := room.center.distance_to(entrance)
		if distance > max_distance and room.connections <= 1:
			max_distance = distance
			farthest_room = room

	var exit_tile := farthest_room.center
	draw_large_entry(exit_tile, Constants.DUNGEON_EXIT_ATLAS)
	exit = exit_tile


func draw_large_entry(center: Vector2i, atlas_id: Vector2i):
	for x in range(-1, 2):
		for y in range(-1, 2):
			var cell = center + Vector2i(x, y)
			generated_map.set_cell(cell, LAYER, atlas_id, DUNGEON_CELL_ID)

	
func build_coridors(rooms: Array[Room]):
	var room_centers := PackedVector2Array(rooms.map(func (room): return generated_map.map_to_local(room.center)))
	var vertexes = PackedVector2Array(room_centers)
	
	var delaunay_edges = AdjucencyMatrixGraph.get_delaunay_edges(vertexes)
	var weighted_adjucency_matrix = AdjucencyMatrixGraph.get_weighted_adjucency_matrix(vertexes, delaunay_edges)
	var mst = AdjucencyMatrixGraph.get_minimum_spanning_tree(rng, vertexes, weighted_adjucency_matrix)
	
	return connect_rooms(mst)
				

func connect_rooms(graph: Array) -> Dictionary:
	var coridors := {}
	var connections = []

	for room_index in range(graph.size()):
		var room_connections = graph[room_index]
		for connected_room_index in range(room_connections.size()):
			var connection_key = "{0}{1}".format([min(room_index, connected_room_index), max(room_index, connected_room_index)])
			if connections.has(connection_key) or room_connections[connected_room_index] == 0:
				continue
			
			connections.append(connection_key)

			var room = rooms[room_index]
			room.connections += 1
			var connected_room = rooms[connected_room_index]
			connected_room.connections += 1
			var start = room.get_wall_center_towards(connected_room)
			var end = connected_room.get_wall_center_towards(room)
			var coridor_path = get_simple_path(start, end)

			coridors[connection_key] = coridor_path

			for point in coridor_path:
				place_coridor(point)

	return coridors


func clear_spawned_enemies():
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()

func clear_torches():
	for torch in get_tree().get_nodes_in_group("torches"):
		torch.queue_free()

func clear_boxes():
	for box in get_tree().get_nodes_in_group("boxes"):
		box.queue_free()

func clear_debug():
	for debug_node in debug_nodes:
		debug_node.queue_free()
	debug_nodes = []



## Функция для генерации комнаты на фиксированной позиции
func generate_random_room() -> Room:
	var room_size = ROOM_SIZE
	var room_position
	if isFirstRoom:
		room_position = Vector2i(0, 0)
		isFirstRoom = false
		room_size = Vector2i(11, 11)
	else:
		room_position = get_random_neighbour_position()
		
	if room_position == null:
		return null
	
	return Room.new(room_size, room_position)


func get_random_neighbour_position():
	var neighbour_positions = []
	var offset
	var base_grid_position
	var direction
	for room in rooms:
		offset = (ROOM_SIZE - room.room_size) / 2
		base_grid_position = room.room_position - offset
		var directions = [
			Vector2i(1, 0),
			Vector2i(-1, 0), 
			Vector2i(0, 1),
			Vector2i(0, -1) 
		]
		
		for dir in directions:
			var neighbour_pos = base_grid_position + dir * (ROOM_SIZE + Vector2i(ROOM_SPACING, ROOM_SPACING))
			neighbour_positions.append(neighbour_pos)

	neighbour_positions.shuffle()

	for pos in neighbour_positions:
		if can_place_room_at(pos):
			return pos

	return null


func can_place_room_at(position: Vector2i) -> bool:

	for x in range(position.x, position.x + ROOM_SIZE.x): 
		for y in range(position.y, position.y + ROOM_SIZE.y):
			var cell = Vector2i(x, y)
			if generated_map.get_cell_source_id(cell) != -1: 
				return false
	return true


func place_room(room: Room):
	var cell_set := room.cells.duplicate()
	for cell in room.cells:
		generated_map.set_cell(cell, 0, Vector2i(rng.randi_range(0, 3), rng.randi_range(6, 8)), DUNGEON_CELL_ID)
		for offset in [
			Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, 1),
			Vector2i(1, -1), Vector2i(-1, -1)]:
			var neighbor = cell + offset
			if not cell_set.has(neighbor) and generated_map.get_cell_source_id(neighbor) == -1:
				generated_map.set_cell(neighbor, LAYER, Constants.DUNGEON_WALL_ATLAS, DUNGEON_CELL_ID)
	
	if room.room_size != Vector2i(11, 11):
		add_inner_walls(room)
		spawn_box(room)
		spawn_torches_in_room(room)
	



func place_coridor(center: Vector2i):

	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var cell_pos = center + Vector2i(dx, dy)
			generated_map.set_cell(cell_pos, LAYER, Vector2i(rng.randi_range(0, 3), rng.randi_range(6, 8)), DUNGEON_CELL_ID)


	for dx in range(-3, 4):
		for dy in range(-3, 4):

			if abs(dx) <= 2 and abs(dy) <= 2:
				continue

			var cell_pos = center + Vector2i(dx, dy)
			if generated_map.get_cell_source_id(cell_pos) == -1:
				generated_map.set_cell(cell_pos, LAYER, Constants.DUNGEON_WALL_ATLAS, DUNGEON_CELL_ID)


func get_simple_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = start
	
	if rng.randi_range(0, 1) == 0:

		while current.x != end.x:
			current.x += signi(end.x - current.x)
			path.append(current)
		while current.y != end.y:
			current.y += signi(end.y - current.y)
			path.append(current)
	else:
		while current.y != end.y:
			current.y += signi(end.y - current.y)
			path.append(current)
		while current.x != end.x:
			current.x += signi(end.x - current.x)
			path.append(current)

	return path


func add_inner_walls(room: Room):
	var used_cells := {}  # Уже занятые внутренние клетки стенами
	var attempts := 10 + rng.randi_range(0, 5)
	
	while attempts > 0:
		attempts -= 1
		var horizontal := rng.randi_range(0, 1) == 0
		var wall_length := rng.randi_range(3, 6)
		
		# Ограничим зону размещения, чтобы стена не выходила за границы и была отступ от краёв
		var margin := 2
		var max_x = room.room_position.x + room.room_size.x - (wall_length if horizontal else 1) - margin
		var max_y = room.room_position.y + room.room_size.y - (1 if horizontal else wall_length) - margin
		var min_x = room.room_position.x + margin
		var min_y = room.room_position.y + margin

		if max_x <= min_x or max_y <= min_y:
			continue

		var start_x := rng.randi_range(min_x, max_x)
		var start_y := rng.randi_range(min_y, max_y)

		var new_wall = []
		var valid := true

		for j in range(wall_length):
			var pos := Vector2i(start_x + j, start_y) if horizontal else Vector2i(start_x, start_y + j)

			# Должна находиться внутри комнаты
			if not room.cells.has(pos):
				valid = false
				break

			# Проверка отступов: расстояние ≥ 2 до других стен
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var check_pos = pos + Vector2i(dx, dy)
					if used_cells.has(check_pos):
						valid = false
						break
				if not valid:
					break

			if not valid:
				break

			new_wall.append(pos)

		if not valid:
			continue

		
		for pos in new_wall:
			generated_map.set_cell(pos, LAYER, Constants.DUNGEON_WALL_ATLAS, DUNGEON_CELL_ID)
			used_cells[pos] = true


func spawn_enemies_in_room(room: Room):
	var valid_cells := []

	# фильтруем клетки
	for cell in room.cells:
		var source_id = generated_map.get_cell_source_id(cell)
		if source_id == -1:
			continue
		var atlas_coords = generated_map.get_cell_atlas_coords(cell)
		if atlas_coords == Constants.DUNGEON_WALL_ATLAS:
			continue

		# проверка на стены вокруг
		var is_near_wall := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var neighbor = cell + Vector2i(dx, dy)
				var neighbor_id = generated_map.get_cell_source_id(neighbor)
				if neighbor_id != -1:
					var neighbor_atlas = generated_map.get_cell_atlas_coords(neighbor)
					if neighbor_atlas == Constants.DUNGEON_WALL_ATLAS:
						is_near_wall = true
						break
			if is_near_wall:
				break

		if not is_near_wall:
			valid_cells.append(cell)

	if valid_cells.is_empty():
		return

	valid_cells.shuffle()

	var placed_cells := []
	var enemies_to_spawn = min(max_enemies_per_room, valid_cells.size())
	for cell in valid_cells:
		# Проверка на дистанцию
		var too_close = false
		for placed in placed_cells:
			if placed.distance_to(cell) < min_enemy_distance:
				too_close = true
				break
		if too_close:
			continue

		var enemy_type = get_random_enemy_type_by_weight()
		var enemy_instance = null

		match enemy_type:
			"LittleOrc":
				enemy_instance = little_orc.instantiate()
			"BigOrc":
				enemy_instance = little_orc.instantiate()
			"MiniDemon":
				enemy_instance = little_orc.instantiate()
			"Slug":
				enemy_instance = little_orc.instantiate()

		if enemy_instance:
			enemy_instance.global_position = generated_map.map_to_local(cell)
			add_child(enemy_instance)
			
			enemy_instance.connect("died", Callable(self, "_on_enemy_died").bind(room.enemies, room))

			
			spawned_enemies.append(enemy_instance)
			room.enemies.append(enemy_instance)
			placed_cells.append(cell)


		if placed_cells.size() >= enemies_to_spawn:
			break


func _on_enemy_died(enemy, room_enemies: Array, room: Room):
	if enemy in room_enemies:
		room_enemies.erase(enemy)

	if enemy in spawned_enemies:
		spawned_enemies.erase(enemy)

	if room_enemies.is_empty():
		if room.box:
			room.open_chest()
	

func get_random_enemy_type_by_weight() -> String:
	var total_weight = 0
	for weight in enemy_spawn_weights.values():
		total_weight += weight

	var random_pick = randi() % total_weight
	var current = 0
	for type in enemy_spawn_weights.keys():
		current += enemy_spawn_weights[type]
		if random_pick < current:
			return type
	return "Slug"  # fallback


func spawn_torches_in_room(room: Room):
	var torch_count = rng.randi_range(2, 8)
	var attempts = 15
	
	var used_positions: Array[Vector2i] = []
	
	while torch_count > 0 and attempts > 0:
		attempts -= 1
		var cell = room.cells[rng.randi_range(0, room.cells.size() - 1)]
		
		# Пропускаем, если клетка занята стеной или врагом
		if generated_map.get_cell_atlas_coords(cell) == Constants.DUNGEON_WALL_ATLAS:
			continue
		if used_positions.has(cell):
			continue

		var world_pos = generated_map.map_to_local(cell)
		

		# Создаём факел
		var torch = TorchScene.instantiate()
		torch.position = world_pos
		torch.add_to_group("torches")
		add_child(torch)
		
		used_positions.append(cell)
		torch_count -= 1



func spawn_box(room):
	var max_tries = 100
	var box = box_scene.instantiate()

	for i in max_tries:
		var cell = room.cells[rng.randi_range(0, room.cells.size() - 1)]
		var tile_coords = generated_map.get_cell_atlas_coords(cell)

		# Пропустить, если это стена (например, tile_id == wall_id)
		if tile_coords == Constants.DUNGEON_WALL_ATLAS:
			continue

		var world_pos = generated_map.map_to_local(cell)

		var query = PhysicsPointQueryParameters2D.new()
		query.position = world_pos
		query.collide_with_areas = true
		query.collide_with_bodies = true

		var result = get_world_2d().direct_space_state.intersect_point(query, 1)
		
		# Проверяем, что точка свободна (без тел и факелов)
		if result.is_empty():
			box.position = world_pos
			box.add_to_group("boxes")
			add_child(box)
			
			room.box = box
			return

	


class AdjucencyMatrixGraph:
	
	static func get_delaunay_edges(vertexes: PackedVector2Array) -> PackedInt32Array:
		return Geometry2D.triangulate_delaunay(vertexes)
	
	static func get_empty_adjucency_matrix(vertexes: PackedVector2Array) -> Array:
		var adjucency_matrix = range(vertexes.size())
		for i in adjucency_matrix:
			adjucency_matrix[i] = range(vertexes.size()).map(func (i): return 0)
		
		return adjucency_matrix
	
	static func get_weighted_adjucency_matrix(vertexes: PackedVector2Array, delaunay_edges: PackedInt32Array):
		var adjucency_matrix = get_empty_adjucency_matrix(vertexes)
		
		for i in range(delaunay_edges.size() / 3):
			var index = i * 3

			var first = delaunay_edges[index]
			var second = delaunay_edges[index + 1]
			var third = delaunay_edges[index + 2]
			
			adjucency_matrix[first][second] = vertexes[first].distance_squared_to(vertexes[second])
			adjucency_matrix[first][third] = vertexes[first].distance_squared_to(vertexes[third])
			
			adjucency_matrix[second][first] = vertexes[second].distance_squared_to(vertexes[first])
			adjucency_matrix[second][third] = vertexes[second].distance_squared_to(vertexes[third])
			
			adjucency_matrix[third][first] = vertexes[third].distance_squared_to(vertexes[first])
			adjucency_matrix[third][second] = vertexes[third].distance_squared_to(vertexes[second])
		
		return adjucency_matrix
	
	
	# Prims Algorithm 
	static func get_minimum_spanning_tree(rng: RandomNumberGenerator, vertexes: PackedVector2Array, weighted_adjucency_matrix: Array) -> Array:
		var minimum_spanning_tree = get_empty_adjucency_matrix(vertexes)
		var fringe_vertexes = range(vertexes.size())
		var opened_vertexes = []
		
		var first_vertex = rng.randi_range(0, minimum_spanning_tree.size() - 1)
		fringe_vertexes.erase(first_vertex)
		opened_vertexes.append(first_vertex)
		
		while fringe_vertexes.size() > 0:
			var best_edge
			
			for opened_vertex in opened_vertexes:
				var opened_vertex_edges : Array = weighted_adjucency_matrix[opened_vertex]
				for vertex_index in range(opened_vertex_edges.size()):
					var vertex_weight = opened_vertex_edges[vertex_index]
					if vertex_weight == 0 or not fringe_vertexes.has(vertex_index):
						continue
						
					if best_edge == null or vertex_weight < best_edge.weight:
						best_edge = {
							"opened": opened_vertex,
							"fringe": vertex_index,
							"weight": vertex_weight
						}
						
			if best_edge == null:
				break
			
			fringe_vertexes.erase(best_edge.fringe)
			opened_vertexes.append(best_edge.fringe)
			
			minimum_spanning_tree[best_edge.opened][best_edge.fringe] = 1
			minimum_spanning_tree[best_edge.fringe][best_edge.opened] = 1
		
		return minimum_spanning_tree


class Room:
	var room_size: Vector2i
	var room_position: Vector2i
	var cells: Array[Vector2i]
	var center: Vector2i
	var connections: int = 0
	var enemies: Array[Node] = []
	var box: Node2D = null
	func _init(_room_size: Vector2i, _room_position: Vector2i):
		room_size = _room_size
		room_position = _room_position
		center = _room_position
		for x in range(room_size.x):
			for y in range(room_size.y):
				cells.append(room_position + Vector2i(x, y))
	
	
	func get_wall_center_towards(other: Room) -> Vector2i:
		var delta = other.center - center
		
		if abs(delta.x) > abs(delta.y):
			var y = room_position.y + int(room_size.y / 2)
			if delta.x > 0:
				return Vector2i(room_position.x + room_size.x-1, y)
			else:
				return Vector2i(room_position.x, y)
		else:
			var x = room_position.x + int(room_size.x / 2)
			if delta.y > 0:
				return Vector2i(x, room_position.y + room_size.y-1)
			else:
				return Vector2i(x, room_position.y)
	
	func open_chest():
		if box:
			box.open_chest()
		
