extends Camera2D


@onready var player = %Knight as Node2D


func _process(delta: float) -> void:
	global_position = player.global_position
