extends Object
class_name Room

var room_size: Vector2i
var room_position: Vector2i
var cells: Array[Vector2i]
var center: Vector2i
var connections: int = 0
var enemies: Array[Node] = []

var box: Node2D = null
var area_room: Area2D = null
var tile_size = 16


var entrances: Array[Vector2i] = []

signal request_block_entrances(room)
signal request_unblock_entrances(room)


func _init(_room_size: Vector2i, _room_position: Vector2i):
	room_size = _room_size
	room_position = _room_position
	center = _room_position+_room_size/2
	for x in range(room_size.x):
		for y in range(room_size.y):
			cells.append(room_position + Vector2i(x, y))


func get_wall_center_towards(other: Room) -> Vector2i:
	var delta = other.center - center
	
	if abs(delta.x) > abs(delta.y):
		var y = room_position.y + int(room_size.y / 2)
		if delta.x > 0:
			return Vector2i(room_position.x + room_size.x, y)
		else:
			return Vector2i(room_position.x-1, y)
	else:
		var x = room_position.x + int(room_size.x / 2)
		if delta.y > 0:
			return Vector2i(x, room_position.y + room_size.y)
		else:
			return Vector2i(x, room_position.y-1)

		
func create_area_trigger():
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	var size = Vector2(room_size - Vector2i(2, 2))
	shape.extents = size / 2.0 * tile_size
	collision.shape = shape

	area.add_child(collision)

	var offset = Vector2(room_position + Vector2i(1, 1)) + size / 2.0
	area.position = offset * tile_size  
	area.name = "RoomArea"
	area.set_meta("room_ref", self)
	area.set_collision_layer_value(2, true)
	area.set_collision_mask_value(1, true)

	area_room = area
	return area
