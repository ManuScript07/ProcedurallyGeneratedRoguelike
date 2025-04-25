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
	attack_ability.play("attack_anim")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack_anim":
		attack_ability.play("idle")
