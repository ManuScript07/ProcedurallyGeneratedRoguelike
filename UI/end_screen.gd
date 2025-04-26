extends CanvasLayer

class_name  EndScreen




func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://Level/level.tscn")


func _on_выход_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/StartMenu/start_menu.tscn")
