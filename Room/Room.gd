#extends Node
#
#
#
#class Room:
	#var room_size: Vector2i
	#var room_position: Vector2i
	#var cells: Array[Vector2i]
	#var center: Vector2i
	#var connections: int = 0
	#var enemies: Array[Node] = []
	#var box: Node2D
	#func _init(_room_size: Vector2i, _room_position: Vector2i):
		#room_size = _room_size
		#room_position = _room_position
		#center = _room_position
		#for x in range(room_size.x):
			#for y in range(room_size.y):
				#cells.append(room_position + Vector2i(x, y))
	#
	#
	#func get_wall_center_towards(other: Room) -> Vector2i:
		#var delta = other.center - center
		#
		#if abs(delta.x) > abs(delta.y):
			#var y = room_position.y + int(room_size.y / 2)
			#if delta.x > 0:
				#return Vector2i(room_position.x + room_size.x-1, y)
			#else:
				#return Vector2i(room_position.x, y)
		#else:
			#var x = room_position.x + int(room_size.x / 2)
			#if delta.y > 0:
				#return Vector2i(x, room_position.y + room_size.y-1)
			#else:
				#return Vector2i(x, room_position.y)
