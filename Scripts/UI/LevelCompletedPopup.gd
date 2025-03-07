extends Control


export(int) var level:int = 1

onready var title:Label = $Window/Title
onready var next_button:TextureButton = $Window/VBoxContainer/NextButton

signal ok

func _ready() -> void:
	if Globals.level == Globals.ALL_LEVELS:
		next_button.visible = false
	title.text = tr("POPUP_LEVELCOMP_TITLE")%level


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_RetryButton_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_HomeButton_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene("res://Scenes/UI/Main.tscn")


func _on_NextButton_pressed() -> void:
	get_tree().paused = false
	Globals.level += 1
	get_tree().reload_current_scene()
