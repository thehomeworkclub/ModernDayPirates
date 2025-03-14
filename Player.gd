extends Node3D

@export var mouse_sensitivity: float = 0.1
var max_health: int = 10
var health: int = max_health
var in_vr: bool = false

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var gun_pivot = $Head/GunPivot
var info_board = null

# XR references
@onready var xr_origin = $XROrigin3D
@onready var xr_camera = $XROrigin3D/XRCamera3D
@onready var right_controller = $XROrigin3D/XRController3DRight
@onready var left_controller = $XROrigin3D/XRController3DLeft

# Hand references
var left_hand_model: Node3D = null
var right_hand_model: Node3D = null
var left_hand_joints: Array = []
var right_hand_joints: Array = []

# Default hand pose (relaxed hand)
var default_hand_pose = {
	"left": [],
	"right": []
}

# Health display
var heart_container
var heart_sprites = []

# UI interaction
var right_ray: RayCast3D
var right_laser: MeshInstance3D
var pointing_at_ui: bool = false

func _ready() -> void:
	# CRITICAL: Add to Player group for targeting
	add_to_group("Player")
	
	# Reset health on spawn/respawn
	health = max_health
	print("DEBUG: Player health reset to ", health)
	
	# Make sure we're not at the origin (0,0,0)
	if global_position == Vector3.ZERO:
		# Use the original transform position from the scene
		var expected_position = Vector3(0, 7.24827, -30.0)
		global_position = expected_position
		print("DEBUG: Fixed player position to ", global_position)
	
	# Set up direct health display
	create_direct_health_display()
	
	# Connect to GameManager signals
	GameManager.vr_mode_changed.connect(_on_vr_mode_changed)
	
	# Always initialize VR mode directly
	initialize_vr()
	
	# Player initialization
	print("DEBUG: Player initialized with health: ", health, "/", max_health)

func _on_vr_mode_changed(enabled: bool) -> void:
	print("DEBUG: VR mode changed to ", enabled)
	if enabled:
		initialize_vr()
	else:
		initialize_desktop()

func initialize_desktop() -> void:
	# Make sure VR is disabled
	get_viewport().use_xr = false
	in_vr = false
	
	# Make sure traditional camera is enabled
	head.visible = true
	
	# Set up mouse capture for gameplay
	capture_mouse()
	
	print("DEBUG: Desktop mode initialized")

func initialize_vr() -> void:
	print("DEBUG: Forcing XR mode activation")
	
	# Enable XR regardless of interface check
	get_viewport().use_xr = true
	in_vr = true
	
	# Wait a moment for XR to initialize
	await get_tree().create_timer(0.5).timeout
	
	# Check if OpenXR is available - this should always be true after enabling XR
	if XRServer.primary_interface:
		print("DEBUG: XR interface found: ", XRServer.primary_interface.name)
		
		# Initialize the XR interface
		if XRServer.primary_interface.is_initialized():
			print("DEBUG: XR already initialized")
		else:
			print("DEBUG: Initializing XR interface")
			XRServer.primary_interface.initialize()
		
		# Connect XR signals
		if right_controller:
			print("DEBUG: Setting up right controller (gun controller)")
			if right_controller.button_pressed.is_connected(_on_right_controller_button_pressed):
				print("DEBUG: Right controller signals already connected")
			else:
				right_controller.button_pressed.connect(_on_right_controller_button_pressed)
				right_controller.button_released.connect(_on_right_controller_button_released)
				
			# Create laser pointer for UI interaction
			setup_vr_interaction_pointer()
		else:
			print("DEBUG: Right controller not found, will try again later")
		
		if left_controller:
			print("DEBUG: Setting up left controller (movement controller)")
			if left_controller.button_pressed.is_connected(_on_left_controller_button_pressed):
				print("DEBUG: Left controller signals already connected")
			else:
				left_controller.button_pressed.connect(_on_left_controller_button_pressed)
				left_controller.button_released.connect(_on_left_controller_button_released)
		else:
			print("DEBUG: Left controller not found, will try again later")
		
		# Disable traditional camera in VR mode
		head.visible = false
		
		# Move gun to right controller (if it exists)
		if right_controller and gun_pivot:
			var gun_ref = gun_pivot.get_node("Gun")
			if gun_ref:
				# Remove gun from head
				gun_pivot.remove_child(gun_ref)
				# Add gun to right controller
				right_controller.add_child(gun_ref)
				# Position gun correctly on controller
				gun_ref.transform.basis = Basis.IDENTITY
				gun_ref.position = Vector3(0, 0, -0.1)
				print("DEBUG: Gun moved to right controller")
		
		# Print XR status
		print("DEBUG: XR mode successfully activated")
		print("DEBUG: Current interfaces: ", XRServer.get_interface_count())
		print("DEBUG: Primary interface: ", XRServer.primary_interface.name)
		
		# Verify OpenXR action map is loaded
		var xr_interface_node = get_tree().current_scene.get_node_or_null("XRInteractionSettings/XRInterface")
		if xr_interface_node:
			print("DEBUG: XR interface node found with action map: ", xr_interface_node.action_map)
		else:
			print("WARNING: XR interface node not found in scene")
	else:
		# This should not typically happen if VR is set up properly
		print("ERROR: No XR interface available despite enabling XR mode")
		print("DEBUG: Attempting fallback to desktop mode")
		call_deferred("initialize_desktop")
		
		# Show a warning to the user
		var dialog = AcceptDialog.new()
		dialog.title = "VR Not Available"
		dialog.dialog_text = "OpenXR could not be initialized. The game will run in desktop mode instead.\n\nPlease ensure your VR headset is connected and SteamVR/Oculus software is running."
		dialog.get_ok_button().text = "Continue"
		get_tree().root.add_child(dialog)
		dialog.popup_centered()

func setup_vr_interaction_pointer() -> void:
	if !right_controller:
		print("ERROR: Cannot set up VR interaction pointer - right controller not found")
		return
		
	print("DEBUG: Setting up VR interaction pointer")
	
	# Set up right hand model
	setup_right_hand()
	
	# Set up left hand model
	if left_controller:
		setup_left_hand()
	
	# Create ray cast for pointer
	right_ray = RayCast3D.new()
	right_ray.name = "UIRayCast"
	right_ray.target_position = Vector3(0, 0, -10)  # 10 meter ray
	right_ray.collision_mask = 0x7FFFFFFF  # All layers for now - can be optimized later
	right_ray.collide_with_areas = true
	right_ray.collide_with_bodies = true
	right_controller.add_child(right_ray)
	
	# Create visible laser beam
	right_laser = MeshInstance3D.new()
	right_laser.name = "LaserBeam"
	
	var laser_material = StandardMaterial3D.new()
	laser_material.albedo_color = Color(0.1, 0.8, 1.0, 0.6)
	laser_material.emission_enabled = true
	laser_material.emission = Color(0.1, 0.8, 1.0)
	laser_material.emission_energy_multiplier = 2.0
	
	var laser_mesh = CylinderMesh.new()
	laser_mesh.top_radius = 0.002
	laser_mesh.bottom_radius = 0.002
	laser_mesh.height = 1.0
	laser_mesh.material = laser_material
	right_laser.mesh = laser_mesh
	
	# Position and orient the laser beam
	right_laser.transform.basis = Basis(Vector3(1, 0, 0), PI/2)  # Rotated to point forward
	right_laser.transform.origin = Vector3(0, 0, -0.5)  # Centered in front
	right_laser.visible = false  # Only show when pointing
	right_controller.add_child(right_laser)
	
	print("DEBUG: VR interaction pointer setup complete")

func setup_right_hand() -> void:
	# Create hand container with physics properties
	var hand_container = Node3D.new()
	hand_container.name = "RightHandModel"
	
	# Add a RigidBody3D for physics-based tracking
	var hand_body = RigidBody3D.new()
	hand_body.name = "RightHandBody"
	hand_body.gravity_scale = 0.0  # No gravity effect
	hand_body.linear_damp = 5.0    # Damping to prevent excessive movement
	hand_body.angular_damp = 5.0
	hand_body.continuous_cd = true # Continuous collision detection
	hand_body.max_contacts_reported = 4
	hand_body.contact_monitor = true
	hand_body.can_sleep = false
	hand_container.add_child(hand_body)
	
	# Load the Oculus hand model
	var hand_scene = load("res://assets/guns_hands/Plugins/Oculus Hands/Models/r_hand_skeletal_lowres.fbx")
	if hand_scene:
		# Instance the hand model
		var hand_instance = hand_scene.instantiate()
		if hand_instance:
			# Add the hand model to the physics body
			hand_body.add_child(hand_instance)
			
			# Store the hand model for later use
			right_hand_model = hand_instance
			
			# Add an AnimationPlayer for hand animations
			var anim_player = AnimationPlayer.new()
			anim_player.name = "RightHandAnimator"
			hand_instance.add_child(anim_player)
			
			# Load the default animation
			var default_anim = load("res://assets/guns_hands/Plugins/Oculus Hands/Animations/r_hand_default_anim.fbx")
			if default_anim:
				anim_player.add_animation("default", default_anim)
				anim_player.play("default")
			
			# Load the fist animation
			var fist_anim = load("res://assets/guns_hands/Plugins/Oculus Hands/Animations/r_hand_fist_anim.fbx")
			if fist_anim:
				anim_player.add_animation("fist", fist_anim)
			
			# Load the pinch animation
			var pinch_anim = load("res://assets/guns_hands/Plugins/Oculus Hands/Animations/r_hand_pinch_anim.fbx")
			if pinch_anim:
				anim_player.add_animation("pinch", pinch_anim)
			
			# Collect all the joints in the hand model
			collect_hand_joints(hand_instance, "right")
			
			# Apply default pose
			apply_hand_pose(right_hand_model, "right", default_hand_pose["right"])
			
			# Position the hand correctly - adjust offset for better alignment
			hand_container.transform.origin = Vector3(0.03, -0.05, -0.1)
			
			# Add the hand container to the controller
			right_controller.add_child(hand_container)
			
			# Add collision shape for the hand
			var collision_shape = CollisionShape3D.new()
			collision_shape.name = "HandCollision"
			var shape = BoxShape3D.new()
			shape.size = Vector3(0.08, 0.12, 0.08)  # Size that covers the hand
			collision_shape.shape = shape
			hand_body.add_child(collision_shape)
			
			# Connect signals for collision detection
			hand_body.body_entered.connect(_on_hand_body_entered)
			hand_body.body_exited.connect(_on_hand_body_exited)
			
			print("DEBUG: Right hand model loaded successfully with physics and animations")
		else:
			print("ERROR: Failed to instance right hand model")
			create_fallback_hand(hand_container, right_controller)
	else:
		print("ERROR: Failed to load right hand model")
		create_fallback_hand(hand_container, right_controller)

func setup_left_hand() -> void:
	# Create hand container with physics properties
	var hand_container = Node3D.new()
	hand_container.name = "LeftHandModel"
	
	# Add a RigidBody3D for physics-based tracking
	var hand_body = RigidBody3D.new()
	hand_body.name = "LeftHandBody"
	hand_body.gravity_scale = 0.0  # No gravity effect
	hand_body.linear_damp = 5.0    # Damping to prevent excessive movement
	hand_body.angular_damp = 5.0
	hand_body.continuous_cd = true # Continuous collision detection
	hand_body.max_contacts_reported = 4
	hand_body.contact_monitor = true
	hand_body.can_sleep = false
	hand_container.add_child(hand_body)
	
	# Load the Oculus hand model
	var hand_scene = load("res://assets/guns_hands/Plugins/Oculus Hands/Models/l_hand_skeletal_lowres.fbx")
	if hand_scene:
		# Instance the hand model
		var hand_instance = hand_scene.instantiate()
		if hand_instance:
			# Add the hand model to the physics body
			hand_body.add_child(hand_instance)
			
			# Store the hand model for later use
			left_hand_model = hand_instance
			
			# Add an AnimationPlayer for hand animations
			var anim_player = AnimationPlayer.new()
			anim_player.name = "LeftHandAnimator"
			hand_instance.add_child(anim_player)
			
			# Load the default animation
			var default_anim = load("res://assets/guns_hands/Plugins/Oculus Hands/Animations/l_hand_default_anim.fbx")
			if default_anim:
				anim_player.add_animation("default", default_anim)
				anim_player.play("default")
			
			# Load the fist animation
			var fist_anim = load("res://assets/guns_hands/Plugins/Oculus Hands/Animations/l_hand_fist_anim.fbx")
			if fist_anim:
				anim_player.add_animation("fist", fist_anim)
			
			# Load the pinch animation
			var pinch_anim = load("res://assets/guns_hands/Plugins/Oculus Hands/Animations/l_hand_pinch_anim.fbx")
			if pinch_anim:
				anim_player.add_animation("pinch", pinch_anim)
			
			# Collect all the joints in the hand model
			collect_hand_joints(hand_instance, "left")
			
			# Apply default pose
			apply_hand_pose(left_hand_model, "left", default_hand_pose["left"])
			
			# Position the hand correctly - adjust offset for better alignment
			hand_container.transform.origin = Vector3(-0.03, -0.05, -0.1)
			
			# Add the hand container to the controller
			left_controller.add_child(hand_container)
			
			# Add collision shape for the hand
			var collision_shape = CollisionShape3D.new()
			collision_shape.name = "HandCollision"
			var shape = BoxShape3D.new()
			shape.size = Vector3(0.08, 0.12, 0.08)  # Size that covers the hand
			collision_shape.shape = shape
			hand_body.add_child(collision_shape)
			
			# Connect signals for collision detection
			hand_body.body_entered.connect(_on_hand_body_entered)
			hand_body.body_exited.connect(_on_hand_body_exited)
			
			print("DEBUG: Left hand model loaded successfully with physics and animations")
		else:
			print("ERROR: Failed to instance left hand model")
			create_fallback_hand(hand_container, left_controller)
	else:
		print("ERROR: Failed to load left hand model")
		create_fallback_hand(hand_container, left_controller)

func create_fallback_hand(container: Node3D, controller: XRController3D) -> void:
	print("DEBUG: Creating fallback hand model")
	
	# Create a more hand-like mesh using primitives
	var hand_material = StandardMaterial3D.new()
	hand_material.albedo_color = Color(0.9, 0.75, 0.7, 1.0)  # Skin-like color
	hand_material.roughness = 0.7
	hand_material.metallic = 0.0
	
	# Create a palm using a flattened sphere
	var palm = MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh = SphereMesh.new()
	palm_mesh.radius = 0.03
	palm_mesh.height = 0.02
	palm_mesh.material = hand_material
	palm.mesh = palm_mesh
	palm.position = Vector3(0, 0, 0)
	container.add_child(palm)
	
	# Add fingers (simple cylinders)
	for i in range(5):  # 5 fingers
		var finger = MeshInstance3D.new()
		finger.name = "Finger" + str(i)
		var finger_mesh = CylinderMesh.new()
		finger_mesh.top_radius = 0.005
		finger_mesh.bottom_radius = 0.008
		finger_mesh.height = 0.04
		finger_mesh.material = hand_material
		finger.mesh = finger_mesh
		
		# Position fingers in a fan-like arrangement
		var angle = (i - 2) * 0.3  # Spread fingers
		finger.position = Vector3(sin(angle) * 0.03, 0, -0.03 - cos(angle) * 0.03)
		finger.rotation = Vector3(PI/2 + angle * 0.5, 0, 0)
		container.add_child(finger)
	
	# Position the hand correctly
	container.transform.origin = Vector3(0, 0, -0.05)
	
	# Add the hand container to the controller
	controller.add_child(container)

func collect_hand_joints(hand_model: Node3D, hand_type: String) -> void:
	# Find all the joints in the hand model
	var joints = []
	
	# Recursively collect all the joints
	collect_joints_recursive(hand_model, joints)
	
	# Store the joints for later use
	if hand_type == "left":
		left_hand_joints = joints
	else:
		right_hand_joints = joints
	
	# Store the default pose
	var default_rotations = []
	for joint in joints:
		default_rotations.append(joint.transform.basis.get_rotation_quaternion())
	
	# Store the default pose
	if hand_type == "left":
		default_hand_pose["left"] = default_rotations
	else:
		default_hand_pose["right"] = default_rotations
	
	print("DEBUG: Collected ", joints.size(), " joints for ", hand_type, " hand")

func collect_joints_recursive(node: Node, joints: Array) -> void:
	# Check if this node is a joint
	if node is Node3D and "joint" in node.name.to_lower():
		joints.append(node)
	
	# Check all children
	for child in node.get_children():
		collect_joints_recursive(child, joints)

func apply_hand_pose(hand_model: Node3D, hand_type: String, pose_rotations: Array) -> void:
	# Get the joints for this hand
	var joints = []
	if hand_type == "left":
		joints = left_hand_joints
	else:
		joints = right_hand_joints
	
	# Apply the pose rotations to the joints
	if joints.size() == pose_rotations.size():
		for i in range(joints.size()):
			joints[i].transform.basis = Basis(pose_rotations[i])
	else:
		print("ERROR: Joint count mismatch for ", hand_type, " hand. Expected ", pose_rotations.size(), " but got ", joints.size())

func _unhandled_input(event: InputEvent) -> void:
	# Only handle mouse input in non-VR mode
	if not in_vr:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# Adjust head (camera) position based on mouse movement with higher sensitivity
			rotate_y(-event.relative.x * mouse_sensitivity * 0.01)  
			head.rotate_x(-event.relative.y * mouse_sensitivity * 0.01)  
			head.rotation.x = clampf(head.rotation.x, -1.5, 1.5)
		
		# Toggle mouse capture on Escape
		if event.is_action_pressed("ui_cancel"):
			toggle_mouse_capture()

var controller_check_timer: float = 0.0
var controller_retry_interval: float = 1.0 # Check every second
var controller_retry_count: int = 0
var max_controller_retries: int = 10 # Give up after 10 attempts (10 seconds)

func _physics_process(delta: float) -> void:
	# Controller retry logic for VR mode
	if in_vr:
		# If controllers aren't connected yet, periodically try to find them
		if (!right_controller || !left_controller) && controller_retry_count < max_controller_retries:
			controller_check_timer += delta
			if controller_check_timer >= controller_retry_interval:
				controller_check_timer = 0.0
				controller_retry_count += 1
				print("DEBUG: Retry finding controllers (attempt ", controller_retry_count, "/", max_controller_retries, ")")
				
				# Try to get updated controller references
				right_controller = $XROrigin3D/XRController3DRight
				left_controller = $XROrigin3D/XRController3DLeft
				
				# If we found them, set them up
				if right_controller:
					print("DEBUG: Right controller found on retry!")
					if !right_controller.button_pressed.is_connected(_on_right_controller_button_pressed):
						right_controller.button_pressed.connect(_on_right_controller_button_pressed)
						right_controller.button_released.connect(_on_right_controller_button_released)
					
					# Set up UI interaction pointer
					setup_vr_interaction_pointer()
					
					# Move gun to right controller if not already done
					if gun_pivot:
						var gun_ref = gun_pivot.get_node_or_null("Gun")
						if gun_ref:
							gun_pivot.remove_child(gun_ref)
							right_controller.add_child(gun_ref)
							gun_ref.transform.basis = Basis.IDENTITY
							gun_ref.position = Vector3(0, 0, -0.1)
							print("DEBUG: Gun moved to right controller on retry")
				
				if left_controller:
					print("DEBUG: Left controller found on retry!")
					if !left_controller.button_pressed.is_connected(_on_left_controller_button_pressed):
						left_controller.button_pressed.connect(_on_left_controller_button_pressed)
						left_controller.button_released.connect(_on_left_controller_button_released)
		
		# Handle the VR laser pointer for UI interaction
		if right_controller and right_ray:
			# Process UI raycast and interaction
			update_vr_pointer(delta)
		
		# Update hand animations based on controller input
		update_hand_animations()
		
		# Apply physics-based tracking to hand models
		apply_hand_physics_tracking(delta)
		
		# VR movement using left controller thumbstick
		if left_controller and left_controller.is_button_pressed("primary"):
			var joystick_value = left_controller.get_vector2("primary")
			
			# Forward/backward movement
			if abs(joystick_value.y) > 0.1:
				translate(-xr_camera.global_transform.basis.z * delta * 10 * joystick_value.y)
			
			# Strafe left/right
			if abs(joystick_value.x) > 0.1:
				translate(xr_camera.global_transform.basis.x * delta * 10 * joystick_value.x)
	else:
		# Traditional keyboard movement for non-VR mode
		if Input.is_action_pressed("move_forward"):
			translate(-global_transform.basis.z * delta * 10)
		if Input.is_action_pressed("move_backward"):
			translate(global_transform.basis.z * delta * 10)
		if Input.is_action_pressed("strafe_left"):
			translate(-global_transform.basis.x * delta * 10)
		if Input.is_action_pressed("strafe_right"):
			translate(global_transform.basis.x * delta * 10)

# Update the VR pointer for UI interaction
func update_vr_pointer(delta: float) -> void:
	if !right_ray or !right_laser:
		return
	
	# Force the raycast to update
	right_ray.force_raycast_update()
	
	# Get the real ray length to adjust the laser visually
	var ray_length = 10.0
	var is_pointing_at_ui = false
	var hit_point = Vector3.ZERO
	
	# Process raycast results
	if right_ray.is_colliding():
		# Get collision point
		hit_point = right_ray.get_collision_point()
		ray_length = right_ray.global_position.distance_to(hit_point)
		
		# Check if we're hitting a UI control
		var collider = right_ray.get_collider()
		if collider:
			if "Control" in str(collider.get_class()):
				is_pointing_at_ui = true
			elif collider.get_parent() and "Control" in str(collider.get_parent().get_class()):
				is_pointing_at_ui = true
			elif collider is Button or collider is CheckBox or collider is TextureButton:
				is_pointing_at_ui = true
			elif collider.get_parent() and (collider.get_parent() is Button or collider.get_parent() is CheckBox or collider.get_parent() is TextureButton):
				is_pointing_at_ui = true
	
	# Update laser visibility and length
	right_laser.visible = true  # Always show the laser
	
	# Adjust laser length and position
	right_laser.mesh.height = ray_length
	right_laser.transform.origin.z = -ray_length / 2
	
	# Update hand visibility based on UI interaction
	if right_hand_model:
		right_hand_model.visible = true
		
		# If pointing at UI, position the hand at the hit point
		if is_pointing_at_ui:
			# Position hand at hit point
			var local_hit = right_controller.to_local(hit_point)
			right_hand_model.transform.origin = local_hit
	
	# Record if we're pointing at UI for trigger handling
	pointing_at_ui = is_pointing_at_ui

func _on_right_controller_button_pressed(button_name: String) -> void:
	# Handle right controller buttons
	if button_name == "trigger_click" or button_name == "trigger":
		if pointing_at_ui:
			# When pointing at UI, simulate a left mouse button click
			var click_position = get_viewport().size / 2  # Center of the screen
			
			# Create mouse button event
			var mouse_click = InputEventMouseButton.new()
			mouse_click.button_index = MOUSE_BUTTON_LEFT
			mouse_click.pressed = true
			mouse_click.position = click_position
			mouse_click.global_position = click_position
			mouse_click.factor = 1.0
			
			# Process this event to simulate a click
			Input.parse_input_event(mouse_click)
			
			# Provide haptic feedback
			if right_controller:
				right_controller.trigger_haptic_pulse("haptic", 0.2, 0.1, 0.2, 0.0)
				
			print("DEBUG: VR UI click simulated at ", click_position)
		else:
			# Otherwise, just shoot
			Input.action_press("shoot")
	
	if button_name == "ax_button":  # A button on Oculus Touch controller
		# Menu or UI interaction - can be used as an alternative UI interaction button
		if pointing_at_ui:
			# Create mouse button event
			var click_position = get_viewport().size / 2  # Center of screen
			var mouse_click = InputEventMouseButton.new()
			mouse_click.button_index = MOUSE_BUTTON_LEFT
			mouse_click.pressed = true
			mouse_click.position = click_position
			mouse_click.global_position = click_position
			
			# Process event
			Input.parse_input_event(mouse_click)
			
			# Haptic feedback
			if right_controller:
				right_controller.trigger_haptic_pulse("haptic", 0.2, 0.1, 0.2, 0.0)

func _on_right_controller_button_released(button_name: String) -> void:
	# Handle right controller button releases
	if button_name == "trigger_click" or button_name == "trigger":
		if pointing_at_ui:
			# Create mouse button release event
			var click_position = get_viewport().size / 2  # Center of the screen
			var mouse_release = InputEventMouseButton.new()
			mouse_release.button_index = MOUSE_BUTTON_LEFT
			mouse_release.pressed = false
			mouse_release.position = click_position
			mouse_release.global_position = click_position
			
			# Process this event
			Input.parse_input_event(mouse_release)
		else:
			# Release shoot action for normal gameplay
			Input.action_release("shoot")
	
	if button_name == "ax_button" and pointing_at_ui:
		# Release A/X button when pointing at UI
		var click_position = get_viewport().size / 2
		var mouse_release = InputEventMouseButton.new()
		mouse_release.button_index = MOUSE_BUTTON_LEFT
		mouse_release.pressed = false
		mouse_release.position = click_position
		mouse_release.global_position = click_position
		Input.parse_input_event(mouse_release)

func _on_left_controller_button_pressed(button_name: String) -> void:
	# Handle left controller buttons
	if button_name == "by_button":  # B button on Oculus Touch controller
		# Could be used for alternate functions or menu access
		pass

func _on_left_controller_button_released(button_name: String) -> void:
	# Handle left controller button releases
	pass

func toggle_mouse_capture() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		release_mouse()
	else:
		capture_mouse()

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("DEBUG: Mouse released for UI interaction")

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("DEBUG: Mouse captured for gameplay")

# Create a reliable 2D health display
func create_direct_health_display() -> void:
	print("DEBUG: Setting up direct health display")
	
	# Remove any existing HUD first
	if has_node("HealthHUD"):
		get_node("HealthHUD").queue_free()
	
	# Create canvas layer
	var canvas = CanvasLayer.new()
	canvas.name = "HealthHUD"
	add_child(canvas)
	
	# Create container
	heart_container = HBoxContainer.new()
	heart_container.name = "HeartContainer"
	heart_container.position = Vector2(20, 20)  # Top-left corner
	canvas.add_child(heart_container)
	
	# Update hearts display
	update_hearts()

# Update hearts when health changes
func update_hearts() -> void:
	# Safety check
	if not is_instance_valid(heart_container):
		print("ERROR: Heart container not valid")
		return
		
	# Clear existing hearts
	for heart in heart_sprites:
		if is_instance_valid(heart):
			heart.queue_free()
	heart_sprites.clear()
	
	# Load textures
	var full_heart = load("res://art/fullheart.png")
	var empty_heart = load("res://art/emptyheart.png")
	
	if full_heart == null or empty_heart == null:
		print("ERROR: Failed to load heart textures")
		return
	
	# Create heart textures
	for i in range(max_health):
		var heart = TextureRect.new()
		heart.name = "Heart_" + str(i)
		heart.texture = full_heart if i < health else empty_heart
		heart.custom_minimum_size = Vector2(32, 32)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_container.add_child(heart)
		heart_sprites.append(heart)
	
	print("DEBUG: Updated health display: ", health, "/", max_health)

func take_damage(amount: int) -> void:
	print("DEBUG: Player took " + str(amount) + " damage!")
	health -= amount
	if health <= 0:
		health = 1
	
	# Update health display
	update_hearts()

func reset_health() -> void:
	health = max_health
	print("DEBUG: Player health reset to ", health)
	
	# Update health display
	update_hearts()

# Hand collision handling
func _on_hand_body_entered(body: Node) -> void:
	print("DEBUG: Hand collided with: ", body.name)
	
	# Get the hand that collided (left or right)
	var hand_body = body.get_parent()
	var hand_name = "unknown"
	if hand_body:
		hand_name = hand_body.name
	
	# Provide haptic feedback based on which hand collided
	if hand_name == "RightHandBody" and right_controller:
		right_controller.trigger_haptic_pulse("haptic", 0.3, 0.1, 0.5, 0.0)
		
		# Play fist animation when colliding with objects
		var anim_player = right_hand_model.get_node_or_null("RightHandAnimator")
		if anim_player and anim_player.has_animation("fist"):
			anim_player.play("fist")
	
	elif hand_name == "LeftHandBody" and left_controller:
		left_controller.trigger_haptic_pulse("haptic", 0.3, 0.1, 0.5, 0.0)
		
		# Play fist animation when colliding with objects
		var anim_player = left_hand_model.get_node_or_null("LeftHandAnimator")
		if anim_player and anim_player.has_animation("fist"):
			anim_player.play("fist")

func _on_hand_body_exited(body: Node) -> void:
	print("DEBUG: Hand stopped colliding with: ", body.name)
	
	# Get the hand that stopped colliding (left or right)
	var hand_body = body.get_parent()
	var hand_name = "unknown"
	if hand_body:
		hand_name = hand_body.name
	
	# Return to default animation based on which hand stopped colliding
	if hand_name == "RightHandBody":
		var anim_player = right_hand_model.get_node_or_null("RightHandAnimator")
		if anim_player and anim_player.has_animation("default"):
			anim_player.play("default")
	
	elif hand_name == "LeftHandBody":
		var anim_player = left_hand_model.get_node_or_null("LeftHandAnimator")
		if anim_player and anim_player.has_animation("default"):
			anim_player.play("default")

# Update hand animations based on controller input
func update_hand_animations() -> void:
	# Right hand animations based on controller input
	if right_controller and right_hand_model:
		var anim_player = right_hand_model.get_node_or_null("RightHandAnimator")
		if anim_player:
			# Get grip and trigger values
			var grip_value = right_controller.get_float("grip")
			var trigger_value = right_controller.get_float("trigger")
			
			# Determine which animation to play based on controller input
			if grip_value > 0.7:
				if not anim_player.current_animation == "fist":
					anim_player.play("fist")
			elif trigger_value > 0.7:
				if not anim_player.current_animation == "pinch":
					anim_player.play("pinch")
			else:
				if not anim_player.current_animation == "default":
					anim_player.play("default")
	
	# Left hand animations based on controller input
	if left_controller and left_hand_model:
		var anim_player = left_hand_model.get_node_or_null("LeftHandAnimator")
		if anim_player:
			# Get grip and trigger values
			var grip_value = left_controller.get_float("grip")
			var trigger_value = left_controller.get_float("trigger")
			
			# Determine which animation to play based on controller input
			if grip_value > 0.7:
				if not anim_player.current_animation == "fist":
					anim_player.play("fist")
			elif trigger_value > 0.7:
				if not anim_player.current_animation == "pinch":
					anim_player.play("pinch")
			else:
				if not anim_player.current_animation == "default":
					anim_player.play("default")

# Apply physics-based tracking to hand models
func apply_hand_physics_tracking(delta: float) -> void:
	# Apply physics to right hand
	if right_controller:
		var hand_container = right_controller.get_node_or_null("RightHandModel")
		if hand_container:
			var hand_body = hand_container.get_node_or_null("RightHandBody")
			if hand_body and hand_body is RigidBody3D:
				# Calculate position and rotation differences
				var target_pos = right_controller.global_transform.origin
				var current_pos = hand_body.global_transform.origin
				var pos_diff = target_pos - current_pos
				
				# Apply force to move hand toward controller
				var linear_force = pos_diff * 20.0  # Adjust strength as needed
				hand_body.apply_central_force(linear_force)
				
				# Calculate rotation difference
				var target_rot = right_controller.global_transform.basis
				var current_rot = hand_body.global_transform.basis
				var rot_diff = current_rot.get_rotation_quaternion().inverse() * target_rot.get_rotation_quaternion()
				
				# Convert to axis-angle
				var axis = Vector3()
				var angle = 0.0
				rot_diff.get_axis_angle(axis, angle)
				if angle > PI:
					angle -= 2 * PI
				
				# Apply torque to rotate hand toward controller orientation
				if angle > 0.01:  # Only apply if there's a significant difference
					var torque = axis.normalized() * angle * 2.0  # Adjust strength as needed
					hand_body.apply_torque(torque)
	
	# Apply physics to left hand
	if left_controller:
		var hand_container = left_controller.get_node_or_null("LeftHandModel")
		if hand_container:
			var hand_body = hand_container.get_node_or_null("LeftHandBody")
			if hand_body and hand_body is RigidBody3D:
				# Calculate position and rotation differences
				var target_pos = left_controller.global_transform.origin
				var current_pos = hand_body.global_transform.origin
				var pos_diff = target_pos - current_pos
				
				# Apply force to move hand toward controller
				var linear_force = pos_diff * 20.0  # Adjust strength as needed
				hand_body.apply_central_force(linear_force)
				
				# Calculate rotation difference
				var target_rot = left_controller.global_transform.basis
				var current_rot = hand_body.global_transform.basis
				var rot_diff = current_rot.get_rotation_quaternion().inverse() * target_rot.get_rotation_quaternion()
				
				# Convert to axis-angle
				var axis = Vector3()
				var angle = 0.0
				rot_diff.get_axis_angle(axis, angle)
				if angle > PI:
					angle -= 2 * PI
				
				# Apply torque to rotate hand toward controller orientation
				if angle > 0.01:  # Only apply if there's a significant difference
					var torque = axis.normalized() * angle * 2.0  # Adjust strength as needed
					hand_body.apply_torque(torque)
