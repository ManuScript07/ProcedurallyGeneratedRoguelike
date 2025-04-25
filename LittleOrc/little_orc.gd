extends CharacterBody2D

var max_speed = 80

signal died(enemy)

func _process(_delta: float) -> void:
	var direction = get_direction_to_player()
	velocity = max_speed*direction
	move_and_slide()


func get_direction_to_player():
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	
	if player != null:
		return (player.global_position - self.global_position).normalized()
		
	return Vector2.ZERO


func _on_area_2d_area_entered(area: Area2D) -> void:
	var tilemap = get_tree().get_first_node_in_group("GeneratedMap")  # Убедись, что TileMap в группе
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	if tilemap != null and tilemap.is_wall_between(global_position, player.global_position):
		return 

	die()

func die():
	emit_signal("died", self)
	queue_free()
