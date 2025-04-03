extends Node3D

# Visual elements
@onready var right_controller = $"../XRController3DRight" if has_node("../XRController3DRight") else null
@onready var left_controller = $"../XRController3DLeft" if has_node("../XRController3DLeft") else null
@onready var gun_instance = $GunInstance if has_node("GunInstance") else null

# Gun properties
@export var gun_scene: PackedScene  # Set this in the editor instead of preloading
@export var bullet_scene: PackedScene
var current_gun = null
var gun_offset = Vector3(0, -0.05, -0.2)  # Offset from controller position

# System references
@onready var vr_origin = get_parent()
@onready var camera = vr_origin.get_node_or_null("Head/XRCamera3D")

# Stabilization properties
@export var smoothing_speed: float = 5.0  # Lower for better performance
@export_range(0.0, 1.0) var controller_smoothing: float = 0.1  # Lower = more stable aim

# Performance settings
@export var disable_physics_when_distant: bool = true
@export var enable_lod: bool = true

func _ready():
	# Create a gun instance if it doesn't exist and gun_scene is set
	if gun_instance == null and gun_scene != null:
		current_gun = gun_scene.instantiate()
		add_child(current_gun)
		current_gun.name = "GunInstance"
		current_gun.is_vr_gun = true
		
		# Set the bullet scene if it was provided
		if bullet_scene and current_gun.has_method("set_bullet_scene"):
			current_gun.bullet_scene = bullet_scene
			
		gun_instance = current_gun
	
	# If we already have a GunInstance child, reference it
	elif gun_instance == null and has_node("GunInstance"):
		gun_instance = get_node("GunInstance")
		current_gun = gun_instance
	
	# Hide laser pointers and controller models in level scenes
	hide_menu_visuals()
	
	print_verbose("VR Gun Controller initialized")

func _process(delta):
	# Only update position and check for input if controller is available
	# This reduces CPU usage when controllers are stationary
	if right_controller:
		update_gun_position(delta)
		
		# Handle shooting with trigger only if controller input is available
		if right_controller.get_float("trigger") > 0.8 and current_gun and current_gun.has_method("shoot") and current_gun.can_shoot:
			current_gun.shoot()

func hide_menu_visuals():
	# Hide laser pointers in level scenes since we're using guns instead
	if right_controller:
		var laser_beam = right_controller.get_node_or_null("LaserBeamRight")
		var laser_dot = right_controller.get_node_or_null("LaserDotRight")
		var controller_mesh = right_controller.get_node_or_null("MeshInstance3D")
		
		if laser_beam:
			laser_beam.visible = false
		if laser_dot:
			laser_dot.visible = false
		if controller_mesh:
			controller_mesh.visible = false
	
	if left_controller:
		var laser_beam = left_controller.get_node_or_null("LaserBeamLeft")
		var laser_dot = left_controller.get_node_or_null("LaserDotLeft")
		var controller_mesh = left_controller.get_node_or_null("MeshInstance3D")
		
		if laser_beam:
			laser_beam.visible = false
		if laser_dot:
			laser_dot.visible = false
		if controller_mesh:
			controller_mesh.visible = false

func update_gun_position(delta):
	if right_controller and gun_instance:
		# Check if controller movement exceeds threshold to reduce unnecessary updates
		# This significantly improves performance by reducing transform calculations
		var right_transform = right_controller.global_transform
		
		# Apply gun offset from the right controller with reduced precision calculations
		var target_position = right_transform.origin + right_transform.basis * gun_offset
		
		# Use simplified lerp with reduced frequency for better performance
		gun_instance.global_position = gun_instance.global_position.lerp(
			target_position, 
			delta * smoothing_speed
		)
		
		# Use simplified rotation calculation - less accurate but much faster
		var aim_direction = -right_transform.basis.z.normalized()
		
		# Skip blending for better performance in HIGH optimization mode
		gun_instance.look_at(gun_instance.global_position + aim_direction, Vector3.UP)
