extends CharacterBody2D

var max_speed = 200

@onready var sprite = $AnimatedSprite2D
@onready var attack_node = $Attack
@onready var health_component: Node = $HealthComponent
@onready var grace_period: Timer = $GracePeriod
@onready var progress_bar: ProgressBar = $ProgressBar

var enemies_colliding = 0
var last_direction_x = 1 

var current_room: Room = null

func _ready() -> void:
	health_component.connect("died", Callable(self, "on_died"))
	health_component.connect("health_changed", on_health_changed)
	health_update()

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

func check_if_damage():
	if enemies_colliding == 0 or !grace_period.is_stopped():
		return
	health_component.take_damage(0.1)
	grace_period.start()
	#print(health_component.current_health)


func health_update():
	progress_bar.value = health_component.get_health_value()

func _on_player_hurt_box_area_entered(area: Area2D) -> void:
	enemies_colliding += 1
	check_if_damage()


func _on_player_hurt_box_area_exited(area: Area2D) -> void:
	enemies_colliding -= 1
	
func on_health_changed():
	health_update()

func on_died(enemy):
	get_tree().change_scene_to_file("res://UI/StartMenu/start_menu.tscn")
	#queue_free()


func _on_grace_period_timeout() -> void:
	check_if_damage()




func _on_player_pos_area_area_entered(area: Area2D) -> void:
	var room = area.get_meta("room_ref")
	current_room = room
	if !room.enemies.is_empty():
		max_speed = 150
		room.emit_signal("request_block_entrances", room)
