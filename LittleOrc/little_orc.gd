extends CharacterBody2D

var max_speed = 80
var active = false

@onready var health_component: Node = $HealthComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var tween = create_tween()

func _ready() -> void:
	health_component.connect("died", Callable(self, "on_died"))

func _process(_delta: float) -> void:
	if !active:
		sprite.play("Idle")
		return

	var direction = get_direction_to_player()
	velocity = max_speed * direction
	move_and_slide()

	# Переключаем анимации в зависимости от движения
	if velocity.length() > 0.1:
		sprite.play("Run")
	else:
		sprite.play("Idle")

	
	
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
