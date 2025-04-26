extends Node


signal died(enemy)
signal health_changed

@export var max_health: float = 10
var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(damage):
	current_health = max(current_health-damage, 0)
	emit_signal("health_changed")
	check_death()


func get_health_value():
	return current_health/max_health
	
func check_death():
	if current_health == 0:
		emit_signal("died", owner)
