extends CharacterBody2D

var max_speed = 80
var active = false
var player_in_range = false
var wander_direction = Vector2.ZERO
var player

@onready var health_component: Node = $HealthComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var tween = create_tween()
@onready var wander_timer = Timer.new()
@onready var is_wandering = false

func _ready() -> void:
	health_component.connect("died", Callable(self, "on_died"))
	wander_timer.wait_time = randf_range(1.5, 3.5)
	wander_timer.one_shot = false
	wander_timer.autostart = true
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	add_child(wander_timer)
	wander_timer.start()
	player = get_tree().get_first_node_in_group("Player") as Node2D

func _process(_delta: float) -> void:
	if !active:
		return
	
	if player_in_range:
		if player:
			var to_player = player.global_position - global_position
			if to_player.length() < 10.0:
				velocity = Vector2.ZERO
			else:
				velocity = to_player.normalized() * max_speed
	else:
		velocity = max_speed * wander_direction if is_wandering else Vector2.ZERO
	
	move_and_slide()

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	
	if velocity.length() > 0.1:
		sprite.play("Run")
	else:
		sprite.play("Idle")

func _on_wander_timer_timeout():
	is_wandering = !is_wandering
	if is_wandering:
		var angle = randf() * TAU
		wander_direction = Vector2(cos(angle), sin(angle)).normalized()
	else:
		wander_direction = Vector2.ZERO
	
	wander_timer.wait_time = randf_range(1.5, 3.5)

	
func get_direction_to_player():
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	
	if player:
		return (player.global_position - self.global_position).normalized()
		
	return Vector2.ZERO


func _on_area_2d_area_entered(area: Area2D) -> void:
	var tilemap = get_tree().get_first_node_in_group("GeneratedMap")  # Убедись, что TileMap в группе
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	if tilemap != null and tilemap.is_wall_between(global_position, player.global_position):
		return 
	flash_damage()
	await get_tree().create_timer(0.3).timeout
	health_component.take_damage(5)
	


func flash_damage():
	tween.kill()
	sprite.self_modulate = Color(1, 0, 0)
	tween = create_tween()
	tween.tween_property(sprite, "self_modulate", Color(1, 1, 1), 0.3)
	

func on_died(enemy):
	queue_free()


func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		player_in_range = true


func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player"):
		player_in_range = false
