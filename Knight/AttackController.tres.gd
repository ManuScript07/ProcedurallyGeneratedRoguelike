extends Node

var attack_range = 100

@onready var attack_ability = $"../../Attack/AnimationPlayer"
# Called when the node enters the scene tree for the first tim
func _ready() -> void:
	attack_ability.play("idle")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		perform_attack()

func perform_attack() -> void:
	#var closest_enemy = find_closest_enemy()
	#var player = get_parent()
	#if closest_enemy:
		#var direction = closest_enemy.global_position.x - player.global_position.x
		#if direction < 0:
			#get_parent().position.x = -abs(get_parent().position.x)  # Перенос меча влево
		#else:
			#get_parent().position.x = abs(get_parent().position.x)   # Перенос меча вправо
	
	attack_ability.play("attack_anim")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack_anim":
		attack_ability.play("idle")
		
func find_closest_enemy() -> Node2D:
	var closest_enemy = null
	var closest_distance = attack_range
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_pos = (enemy as Node2D).global_position
		var player_pos = (get_parent() as Node2D).global_position
		var dist = enemy_pos.distance_to(player_pos)
		if dist < closest_distance:
			closest_distance = dist
			closest_enemy = enemy
	
	return closest_enemy
