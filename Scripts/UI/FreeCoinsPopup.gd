extends Control


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_WatchButton_pressed() -> void:
	get_parent().get_node("Admob").show_rewarded_video()
	queue_free()


func _on_XButton_pressed() -> void:
	queue_free()
