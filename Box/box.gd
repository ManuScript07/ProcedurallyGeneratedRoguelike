extends Node2D


@onready var animation_player = $AnimatedSprite2D

#var room: Room  # Ссылка на комнату, в которой находится сундук

func open_chest():
	animation_player.play("Opening")
