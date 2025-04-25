extends CharacterBody2D

@export var max_speed = 200
@onready var sprite = $AnimatedSprite2D
@onready var attack_node = $Attack

var last_direction_x := 1 

func _process(delta: float) -> void:
	var direction = movement_vector().normalized()
	velocity = max_speed * direction
	
	if direction.length() > 0:
		sprite.play("Run")
		if direction.x != 0:
			last_direction_x = sign(direction.x)

		sprite.flip_h = last_direction_x < 0
		attack_node.scale.x = last_direction_x
	else:
		sprite.play("Idle")

	move_and_slide()

func movement_vector() -> Vector2:
	var movement_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var movement_y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(movement_x, movement_y)
