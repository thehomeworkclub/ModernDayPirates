extends Node3D

# Visual elements
@onready var right_controller = $"../XRController3DRight" if has_node("../XRController3DRight") else null
@onready var left_controller = $"../XRController3DLeft" if has_node("../XRController3DLeft") else null
@onready var gun_instance = $GunInstance if has_node("GunInstance") else null

# Gun properties
@export var gun_scene: PackedScene = preload("res://M16A1Gun.tscn")  # Default to M16A1
@export var bullet_scene: PackedScene
@export var enable_gun_switching: bool = false  # Whether to allow switching between guns
var current_gun = null
var gun_offset = Vector3(0, 0, 0)  # Centered on controller position
var available_guns = {
	"m16a1": preload("res://M16A1Gun.tscn"),
	"ak74": preload("res://AK74Gun.tscn"),
	"scarl": preload("res://SCARLGun.tscn"),
	"hk416": preload("res://HK416Gun.tscn"),
	"mp5": preload("res://MP5Gun.tscn"),
	"mosin": preload("res://MosinNagantGun.tscn"),
	"model1897": preload("res://Model1897Gun.tscn")
}
var current_gun_index = 0

# System references
@onready var vr_origin = get_parent()
@onready var camera = vr_origin.get_node_or_null("Head/XRCamera3D")
@onready var health_display = null

# Stabilization properties
@export var smoothing_speed: float = 10.0  # Higher for more responsive movement
@export_range(0.0, 1.0) var controller_smoothing: float = 0.0  # Zero for precise 1:1 mapping

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
		
		# Add health display to gun
		add_health_display_to_gun()
	
	# If we already have a GunInstance child, reference it
	elif gun_instance == null and has_node("GunInstance"):
		gun_instance = get_node("GunInstance")
		current_gun = gun_instance
	
	# Hide laser pointers and controller models in level scenes
	hide_menu_visuals()
	
	print_verbose("VR Gun Controller initialized")

# Add health display to the current gun
func add_health_display_to_gun():
	if gun_instance != null:
		# Remove existing health display if any
		if health_display != null:
			health_display.queue_free()
		
		# Create new health display
		health_display = Node3D.new()
		health_display.name = "HealthDisplay"
		health_display.script = load("res://GunHealthDisplay.gd")
		
		# Add to gun instance
		gun_instance.add_child(health_display)
		print("Health display added to gun")
		
		# Force the health display to create hearts immediately
		await get_tree().process_frame
		if health_display and health_display.has_method("create_hearts"):
			health_display.create_hearts()
			print("Hearts created for gun health display")
			
			# Force an update to show starting health
			if health_display.has_method("update_hearts"):
				health_display.update_hearts()
				print("Health display initialized with " + str(health_display.current_health) + "/" + str(health_display.max_health) + " hearts")

func _process(delta):
	# Only update position and check for input if controller is available
	# This reduces CPU usage when controllers are stationary
	if right_controller:
		update_gun_position(delta)
		
		# Handle shooting with trigger only if controller input is available
		if right_controller.get_float("trigger") > 0.8 and current_gun and current_gun.has_method("shoot") and current_gun.can_shoot:
			current_gun.shoot()
		
		# Check for gun switching input if enabled
		if enable_gun_switching:
			handle_gun_switching()
			
	# Handle keyboard gun switching for debugging
	if enable_gun_switching:
		handle_keyboard_gun_switching()

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
		# Get the controller's transform
		var right_transform = right_controller.global_transform
		
		# For a 1:1 mapping, directly apply the controller's transform to the gun
		# This makes the controller feel like it IS the gun
		gun_instance.global_transform = right_transform
		
		# If we need to make small adjustments to orientation, we can do it here
		# but we want to maintain the direct mapping feeling
		
		# Apply minimal smoothing only if needed for stability
		if controller_smoothing > 0:
			var prev_position = gun_instance.global_position
			gun_instance.global_position = prev_position.lerp(
				right_transform.origin, 
				delta * smoothing_speed
			)

func handle_gun_switching():
	# Check for gun switching input
	# This uses the "primary" button on the right controller (usually X on Oculus)
	if right_controller.is_button_pressed("primary") and not right_controller.is_button_pressed("secondary"):
		switch_to_next_gun()
	
	# Option to switch to specific gun using secondary + primary as modifier
	if right_controller.is_button_pressed("secondary") and right_controller.is_button_pressed("primary"):
		# You could implement specific gun selection here
		pass

func switch_to_next_gun():
	# Check if we have more than one gun available
	if available_guns.size() <= 1:
		return
	
	# Get the gun keys (names) as an array
	var gun_names = available_guns.keys()
	
	# Increment the index, cycling back to 0 if we reach the end
	current_gun_index = (current_gun_index + 1) % gun_names.size()
	
	# Get the new gun name
	var next_gun_name = gun_names[current_gun_index]
	
	# Switch to the next gun
	switch_gun(next_gun_name)
	
# Handle keyboard input for gun switching (debugging)
func handle_keyboard_gun_switching():
	# Number keys 1-7 for switching guns
	if Input.is_key_pressed(KEY_1):
		switch_gun("m16a1")
	elif Input.is_key_pressed(KEY_2):
		switch_gun("ak74")
	elif Input.is_key_pressed(KEY_3):
		switch_gun("scarl")
	elif Input.is_key_pressed(KEY_4):
		switch_gun("hk416")
	elif Input.is_key_pressed(KEY_5):
		switch_gun("mp5")
	elif Input.is_key_pressed(KEY_6):
		switch_gun("mosin")
	elif Input.is_key_pressed(KEY_7):
		switch_gun("model1897")

func switch_gun(gun_name: String):
	# Check if the gun exists in our available guns
	if not available_guns.has(gun_name):
		print_verbose("Gun not found: " + gun_name)
		return
	
	print_verbose("Switching to gun: " + gun_name)
	
	# Clean up any detached magazines on the left controller
	if left_controller:
		var hand_magazine = left_controller.get_node_or_null("HandMagazine")
		if hand_magazine:
			print_verbose("Cleaning up detached magazine")
			hand_magazine.queue_free()
	
	# Save health value if we have a health display
	var current_health_value = 10  # Default
	if health_display != null:
		current_health_value = health_display.current_health
	
	# Remove the current gun instance
	if current_gun:
		current_gun.queue_free()
	
	# Create the new gun instance
	var new_gun_scene = available_guns[gun_name]
	current_gun = new_gun_scene.instantiate()
	add_child(current_gun)
	current_gun.name = "GunInstance"
	current_gun.is_vr_gun = true
	
	# Set the bullet scene if it was provided
	if bullet_scene and current_gun.has_method("set_bullet_scene"):
		current_gun.bullet_scene = bullet_scene
	
	gun_instance = current_gun
	
	# Add health display to new gun
	add_health_display_to_gun()
	
	# Restore health value if we had one
	if health_display != null:
		health_display.current_health = current_health_value
		health_display.update_hearts()
	
	# Provide haptic feedback for gun switch
	if right_controller:
		right_controller.trigger_haptic_pulse("haptic", 0.2, 0.1, 0.5, 0.0)
