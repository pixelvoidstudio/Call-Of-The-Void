@tool
extends Node2D

@export var file_name :String = ""

@export_tool_button("generate") var action: Callable = _generate

@export var combo := ""

func _generate():
	print(file_name)
	var img = $SubViewportContainer/SubViewport.get_texture().get_image()
	var path = str("res://cards/"+file_name+".png")
	img.save_png(path)
	print("Screenshot saved to: ", path)
	
	
func _process(delta: float) -> void:
	pass
	var size = combo.length()
	if size == 3:
		$"SubViewportContainer/SubViewport/3".show()
		if combo[0].to_lower() == "l":
			$"SubViewportContainer/SubViewport/3/s".texture = load("res://life.png")
		if combo[0].to_lower() == "v":
			$"SubViewportContainer/SubViewport/3/s".texture = preload("res://void.png")
			
		if combo[1].to_lower() == "l":
			$"SubViewportContainer/SubViewport/3/s2".texture = load("res://life.png")
		if combo[1].to_lower() == "v":
			$"SubViewportContainer/SubViewport/3/s2".texture = preload("res://void.png")
		
		if combo[2].to_lower() == "l":
			$"SubViewportContainer/SubViewport/3/s3".texture = load("res://life.png")
		if combo[2].to_lower() == "v":
			$"SubViewportContainer/SubViewport/3/s3".texture = preload("res://void.png")
	else: $"SubViewportContainer/SubViewport/3".hide()
	
	if size == 4:
		$"SubViewportContainer/SubViewport/4".show()
		if combo[0].to_lower() == "l":
			$"SubViewportContainer/SubViewport/4/s2".texture = load("res://life.png")
		if combo[0].to_lower() == "v":
			$"SubViewportContainer/SubViewport/4/s2".texture = preload("res://void.png")
			
		if combo[1].to_lower() == "l":
			$"SubViewportContainer/SubViewport/4/s".texture = load("res://life.png")
		if combo[1].to_lower() == "v":
			$"SubViewportContainer/SubViewport/4/s".texture = preload("res://void.png")
		
		if combo[2].to_lower() == "l":
			$"SubViewportContainer/SubViewport/4/s4".texture = load("res://life.png")
		if combo[2].to_lower() == "v":
			$"SubViewportContainer/SubViewport/4/s4".texture = preload("res://void.png")
		
		if combo[3].to_lower() == "l":
			$"SubViewportContainer/SubViewport/4/s3".texture = load("res://life.png")
		if combo[3].to_lower() == "v":
			$"SubViewportContainer/SubViewport/4/s3".texture = preload("res://void.png")
	else: $"SubViewportContainer/SubViewport/4".hide()
	
	if size == 5:
		$"SubViewportContainer/SubViewport/5".show()
		if combo[0].to_lower() == "l":
			$"SubViewportContainer/SubViewport/5/s2".texture = load("res://life.png")
		if combo[0].to_lower() == "v":
			$"SubViewportContainer/SubViewport/5/s2".texture = preload("res://void.png")
			
		if combo[1].to_lower() == "l":
			$"SubViewportContainer/SubViewport/5/s".texture = load("res://life.png")
		if combo[1].to_lower() == "v":
			$"SubViewportContainer/SubViewport/5/s".texture = preload("res://void.png")
		
		if combo[2].to_lower() == "l":
			$"SubViewportContainer/SubViewport/5/s5".texture = load("res://life.png")
		if combo[2].to_lower() == "v":
			$"SubViewportContainer/SubViewport/5/s5".texture = preload("res://void.png")
		
		if combo[3].to_lower() == "l":
			$"SubViewportContainer/SubViewport/5/s4".texture = load("res://life.png")
		if combo[3].to_lower() == "v":
			$"SubViewportContainer/SubViewport/5/s4".texture = preload("res://void.png")
		
		if combo[4].to_lower() == "l":
			$"SubViewportContainer/SubViewport/5/s3".texture = load("res://life.png")
		if combo[4].to_lower() == "v":
			$"SubViewportContainer/SubViewport/5/s3".texture = preload("res://void.png")
	else: $"SubViewportContainer/SubViewport/5".hide()
