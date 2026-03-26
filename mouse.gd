extends Area2D

var is_picking: bool = true
var passed_first_die: bool = false
var held: bool = false

func _physics_process(delta: float) -> void:
	global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		start_hold()
	elif Input.is_action_just_released("left_click"):
		end_hold()

func _on_body_entered(body: Node2D) -> void:
	if not held:
		return
	
	if body.is_in_group("DICE"):
		if not passed_first_die:
			if body.picked:
				is_picking = false
			else:
				is_picking = true
			
			passed_first_die = true
		
		body.toggle_pick(is_picking)

func start_hold():
	passed_first_die = false
	held = true

func end_hold():
	held = false
