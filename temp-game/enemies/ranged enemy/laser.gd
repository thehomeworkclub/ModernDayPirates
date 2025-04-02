extends Node3D

@export var laser_duration: float = 0.34  # How long the laser lasts
@onready var animation_player = $MeshInstance3D2/AnimationPlayer
@onready var mesh = $MeshInstance3D
@onready var mesh2 = $MeshInstance3D2

func _ready():
	mesh.scale.z = 0.0  # Start with the laser at 0 length
	
	# Connect the animation_finished signal to delete the laser
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Play the animation
	animation_player.play("shoot")  

# Correctly position, rotate, and scale the laser
func set_laser_positions(start_pos: Vector3, end_pos: Vector3):
	var midpoint = (start_pos + end_pos) / 2.0  # Get the midpoint between enemy and player
	global_position = midpoint  # Set laser's position to the midpoint
	look_at(end_pos, Vector3.UP)  # Rotate laser to face the player
	
	var distance = start_pos.distance_to(end_pos)  # Get the total distance
	mesh.scale = Vector3(mesh.scale.x, mesh.scale.y, distance)  # Scale along Z-axis to match distance
	mesh2.scale = mesh.scale

# Called when the animation finishes playing
func _on_animation_finished(anim_name: String):
	if anim_name == "shoot":
		queue_free()  # Remove the laser after the animation finishes
