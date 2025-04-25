extends TileMapLayer

# Предположим, что у тебя есть массив координат/индексов стен

func is_wall_between(from_pos: Vector2, to_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	var ray_params := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	ray_params.collision_mask = 1  # Обязательно укажи правильный слой для стен
	var result = space_state.intersect_ray(ray_params)

	if result:
		return true

	return false
