extends RigidBody2D

@export var launch_speed: float = 800.0
@export var spin_speed: float = 5.0

var die_basis: Basis = Basis() # This stores our 3D rotation

var can_click = false

var l = ["lunie","cat","life","skull","crystal","void"]
@onready var rect = $ColorRect
@onready var DIE_manager = get_parent()
func _ready():
	add_to_group("DICE")
	freeze = true
	rect.material.set_shader_parameter("portal_seed", randf_range(0,100))
	
	# Setup physics for "Bouncy" feel
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.6
	physics_material_override.friction = 0.3
	
	# Make the shader unique for this specific die
	rect.material = rect.material.duplicate()
	
	# Random initial 3D orientation
	die_basis = die_basis.rotated(Vector3.RIGHT, randf() * TAU)
	die_basis = die_basis.rotated(Vector3.UP, randf() * TAU)
	
	update_visibility()


# Inside your RigidBody2D script (HEY HI) (AI) SLOP

var value = -1

@export var die_radius: float = 10.0 # Adjust based on your ColorRect size

func _physics_process(delta):
	var velocity = linear_velocity
	var speed = velocity.length()
	
	if speed > 50.0:
		# 1. Find the rotation axis (perpendicular to movement)
		# If moving (x, y), the perpendicular axis is (-y, x)
		var move_dir = velocity.normalized()
		var rotation_axis = Vector3(-move_dir.y, move_dir.x, 0.0)
		
		# 2. Calculate rotation angle (Arc Length / Radius)
		# Higher speed = faster rotation
		var distance_traveled = speed * delta
		var rotation_angle = distance_traveled / die_radius
		
		# 3. Apply the rotation to our stored 3D basis
		die_basis = die_basis.rotated(rotation_axis, rotation_angle)
		
		# 4. Push to shader
		rect.material.set_shader_parameter("rotation_matrix", die_basis)
	else:
		if DIE_manager.dice_dict[self]["is_rolling"]:
			stop_rolling()

func get_die_value() -> int:
	var b = die_basis
	
	# These vectors represent which direction each NUMBER is facing in 3D space.
	# We compare these to Vector3.BACK because that's where the shader "camera" is.
	var face_vectors = {
		1: b.x,   # If the X-axis points at the camera, show Face 1
		2: -b.x,  # If the negative X-axis points at the camera, show Face 2
		3: b.y,   # If the Y-axis points at the camera, show Face 3
		4: -b.y,  # If the negative Y-axis points at the camera, show Face 4
		5: b.z,   # If the Z-axis points at the camera, show Face 5
		6: -b.z   # If the negative Z-axis points at the camera, show Face 6
	}
	
	var best_face = 1
	var max_dot = -1.0
	
	for val in face_vectors:
		# Vector3.BACK is (0, 0, 1), which is "towards the screen" in Godot
		var dot = face_vectors[val].dot(Vector3.BACK)
		if dot > max_dot:
			max_dot = dot
			best_face = val
	return best_face

func roll_die():
	DIE_manager.dice_dict[self]["is_rolling"] = true
	freeze = false
	# Pick a random 2D direction
	var random_dir = Vector2.RIGHT.rotated(randf() * TAU)
	linear_velocity = (random_dir * launch_speed*2)
	# Add 2D spin (torque) to make the ColorRect itself spin too
	angular_velocity = (randf_range(-20, 20))

func stop_rolling():
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	# Snap to face (using the logic from previous steps)
	freeze = true
	snap_to_face()
	

signal landed(node, face)
func snap_to_face():
	# Use a Tween to rotate 'die_basis' to the nearest 90 degrees
	# This ensures it lands perfectly on one side visually
	var target_euler = die_basis.get_euler()
	target_euler.x = round(target_euler.x / (PI/2)) * (PI/2)
	target_euler.y = round(target_euler.y / (PI/2)) * (PI/2)
	target_euler.z = round(target_euler.z / (PI/2)) * (PI/2)
	
	var target_basis = Basis.from_euler(target_euler)
	var tween = create_tween()
	tween.tween_method(func(b): rect.material.set_shader_parameter("rotation_matrix", b), 
		die_basis, target_basis, 0.4).set_trans(Tween.TRANS_QUART)
	die_basis = target_basis
	value = get_die_value()
	
	landed.emit(self,l[value-1])


var picked: bool = false
var outline_tween: Tween
var star_tween: Tween
func update_visibility():
	if outline_tween and outline_tween.is_running():
		outline_tween.kill()
	
	outline_tween = create_tween()
	outline_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	if picked:
		outline_tween.tween_property(rect.material, "shader_parameter/outline_thickness", 0.15, 0.1)
	else:
		outline_tween.tween_property(rect.material, "shader_parameter/outline_thickness", 0.05, 0.1)
	
	if star_tween and star_tween.is_running():
		star_tween.kill()
	
	star_tween = create_tween()
	star_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	if picked:
		star_tween.tween_property(rect.material, "shader_parameter/portal_star_color", Color.WHITE, 0.1)
	else:
		star_tween.tween_property(rect.material, "shader_parameter/portal_star_color", Color.BLACK, 0.1)

func _on_area_2d_mouse_entered(_area:Area2D) -> void:
	can_click = true
func _on_area_2d_mouse_exited(_area:Area2D) -> void:
	can_click = false

signal picked_updated(node, is_picked)
func toggle_pick(is_picked):
	if (DIE_manager.dice_dict[self]["current_face"] in DIE_manager.non_rerollable) and is_picked:
		return
	
	picked = is_picked
	
	picked_updated.emit(self, picked)
	update_visibility()
