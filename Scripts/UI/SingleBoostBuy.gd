extends Control


signal ok()

export(String) var _subtitle
export(int) var coin

onready var subtitle:Label = $Window/SubTitle
onready var description:Label = $Window/Description

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	subtitle.text = _subtitle
	description.text = tr(description.text)%coin


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_CloseButton_pressed() -> void:
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	get_tree().paused = false
	queue_free()


func _on_Button_pressed() -> void:
	emit_signal("ok")
	queue_free()
