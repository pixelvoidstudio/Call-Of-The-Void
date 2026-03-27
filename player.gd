class_name Player
extends PanelContainer


func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_multiplayer_authority():
		$ColorRect.color.h = randf()
		$Control/Label.text = str(int(str(name)))
