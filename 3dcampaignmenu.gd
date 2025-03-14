extends Node3D

# Dictionary defining voyage data with difficulty parameters
var voyage_data = {
	1: {
		"name": "Calm Waters",
		"difficulty": "Easy",
		"enemy_spawn_rate": 4.0,
		"enemy_speed": 1.0,
		"enemy_health": 1.0
	},
	2: {
		"name": "Rough Seas",
		"difficulty": "Normal",
		"enemy_spawn_rate": 3.0,
		"enemy_speed": 1.2,
		"enemy_health": 1.5
	},
	3: {
		"name": "Storm Warning",
		"difficulty": "Hard",
		"enemy_spawn_rate": 2.0,
		"enemy_speed": 1.5,
		"enemy_health": 2.0
	},
	4: {
		"name": "Hurricane",
		"difficulty": "Very Hard",
		"enemy_spawn_rate": 1.5,
		"enemy_speed": 1.8,
		"enemy_health": 2.5
	},
	5: {
		"name": "Maelstrom",
		"difficulty": "Extreme",
		"enemy_spawn_rate": 1.0,
		"enemy_speed": 2.0,
		"enemy_health": 3.0
	}
}

# VR setup and tracking variables
var _vr_setup_complete = false
var vr_position = Vector3(10.954, -7.596, 4.236)
var vr_look_at = Vector3(10.954, -7.596, 4.236)
var vr_camera_height = 1.8

# Controller and visualization references
var right_controller: XRController3D = null
var left_controller: XRController3D = null 
var right_ray: RayCast3D = null
var left_ray: RayCast3D = null
var right_laser_dot: MeshInstance3D = null
var left_laser_dot: MeshInstance3D = null
var ray_length = 10.0

# Button interaction variables
var buttons = {}
var button_original_positions = {}
var button_press_distance = 0.03
var button_press_duration = 0.15
var active_buttons = {}
var hovering_buttons = {}

# Debug variables
var debug_timer = 0.0
var debug_update_interval = 1.0
var is_changing_scene = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if not _vr_setup_complete:
		setup_vr_environment()
	
	# Get references to XR controllers
	right_controller = $XROrigin3D/XRController3DRight
	left_controller = $XROrigin3D/XRController3DLeft
	
	if right_controller:
		print("Found right controller")
		right_controller.button_pressed.connect(_on_right_controller_button_pressed)
		right_ray = right_controller.get_node("RayCastRight")
		right_laser_dot = right_controller.get_node("LaserDotRight")
	else:
		print("Right controller not found")
	
	if left_controller:
		print("Found left controller")
		left_controller.button_pressed.connect(_on_left_controller_button_pressed)
		left_ray = left_controller.get_node("RayCastLeft")
		left_laser_dot = left_controller.get_node("LaserDotLeft")
	else:
		print("Left controller not found")
	
	call_deferred("setup_clickable_area")
	setup_interactive_buttons()
	set_process_input(true)
	set_process(true)
	
	# Enable more detailed debug output
	OS.set_low_processor_usage_mode(false)
	print_verbose("VR Debug: XR Interface Active = " + str(XRServer.primary_interface != null))

func _process(delta: float) -> void:
	# Update debug timer
	debug_timer += delta
	
	# Update laser pointers
	update_laser_pointers()
	
	# Update button hover states
	update_button_hover_states()
	
	# Update button animations
	update_button_animations(delta)
	
	# Periodically output debug info about controller and hand positions
	if debug_timer >= debug_update_interval:
		debug_timer = 0.0
		
		# Check controller positions
		if right_controller:
			print_verbose("Right controller position: " + str(right_controller.global_transform.origin))
			
			# Check if ray is colliding
			if right_ray and right_ray.is_colliding():
				print_verbose("Right ray hit: " + str(right_ray.get_collider().name))
		
		if left_controller:
			print_verbose("Left controller position: " + str(left_controller.global_transform.origin))
			
			# Check if ray is colliding
			if left_ray and left_ray.is_colliding():
				print_verbose("Left ray hit: " + str(left_ray.get_collider().name))

func update_laser_pointers():
	# Update the laser dot positions based on raycast hits
	if right_ray and right_laser_dot:
		if right_ray.is_colliding():
			right_laser_dot.global_position = right_ray.get_collision_point()
			right_laser_dot.visible = true
		else:
			# Position at the end of the ray if no collision
			right_laser_dot.position = Vector3(0, 0, -ray_length)
			right_laser_dot.visible = true
			
	if left_ray and left_laser_dot:
		if left_ray.is_colliding():
			left_laser_dot.global_position = left_ray.get_collision_point()
			left_laser_dot.visible = true
		else:
			# Position at the end of the ray if no collision
			left_laser_dot.position = Vector3(0, 0, -ray_length)
			left_laser_dot.visible = true

func update_button_hover_states():
	# Clear previous hover states
	hovering_buttons.clear()
	
	# Check right controller
	if right_ray and right_ray.is_colliding():
		var collider = right_ray.get_collider()
		if collider and collider.is_in_group("button"):
			hovering_buttons[collider.name] = "right"
			
	# Check left controller
	if left_ray and left_ray.is_colliding():
		var collider = left_ray.get_collider()
		if collider and collider.is_in_group("button"):
			hovering_buttons[collider.name] = "left"

func update_button_animations(delta):
	# Handle active button press animations
	var buttons_to_remove = []
	for button_name in active_buttons.keys():
		var button_info = active_buttons[button_name]
		button_info.timer += delta
		
		if button_info.timer <= button_press_duration:
			# Animate button press
			var t = button_info.timer / button_press_duration
			var button_mesh = buttons[button_name]
			var original_pos = button_original_positions[button_name]
			
			if button_info.pressing:
				# Press down
				var target_pos = original_pos - Vector3(0, button_press_distance, 0)
				button_mesh.position = original_pos.lerp(target_pos, t)
			else:
				# Release
				var current_pos = button_mesh.position
				var target_pos = original_pos
				button_mesh.position = current_pos.lerp(target_pos, t)
		else:
			# Animation finished
			if not button_info.pressing:
				buttons_to_remove.append(button_name)
				buttons[button_name].position = button_original_positions[button_name]
			else:
				# Keep it pressed while still hovering and holding trigger
				var still_hovering = button_name in hovering_buttons
				var controller_side = button_info.controller
				
				if still_hovering:
					if controller_side == "right" and Input.is_action_pressed("trigger_right"):
						# Keep pressed
						continue
					elif controller_side == "left" and Input.is_action_pressed("trigger_left"):
						# Keep pressed
						continue
				
				# Start release animation
				button_info.pressing = false
				button_info.timer = 0
	
	# Remove completed animations
	for button_name in buttons_to_remove:
		active_buttons.erase(button_name)

func setup_vr_environment() -> void:
	print("Setting up VR environment...")
	
	# Initialize XR interface
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("Found OpenXR interface, initializing...")
		xr_interface.initialize()
		get_viewport().use_xr = true
		_vr_setup_complete = true
		
		# Set VR camera height and position
		var origin = $XROrigin3D if has_node("XROrigin3D") else null
		if origin:
			origin.position = vr_position
			if origin.has_node("XRCamera3D"):
				var camera = origin.get_node("XRCamera3D")
				camera.position.y = vr_camera_height
				camera.look_at(vr_look_at)
	else:
		print("OpenXR interface not found")

func setup_interactive_buttons():
	print("Setting up interactive buttons...")
	
	# Find all button nodes
	var button_container = $InteractiveButtons
	if button_container:
		for child in button_container.get_children():
			if child.is_in_group("button"):
				var button_mesh = child.get_node("ButtonMesh")
				if button_mesh:
					print("Found button: " + child.name)
					buttons[child.name] = button_mesh
					button_original_positions[child.name] = button_mesh.position
	else:
		print("Button container not found")

func setup_clickable_area() -> void:
	print("Setting up clickable areas...")
	# Add clickable areas for voyages
	for voyage_num in voyage_data.keys():
		var area = Area3D.new()
		area.name = "VoyageArea_" + str(voyage_num)
		area.add_to_group("clickable")
		
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(2, 2, 2)  # Size of clickable area
		collision.shape = shape
		area.add_child(collision)
		
		# Position the area based on voyage number
		area.position = Vector3(2 * voyage_num, 0, 0)
		
		add_child(area)

func _on_right_controller_button_pressed(button_name: String):
	if is_changing_scene:
		return
	
	print("Right button pressed: ", button_name)
	if button_name == "trigger_click":
		print("Right trigger click detected")
		
		if right_ray and right_ray.is_colliding():
			var collider = right_ray.get_collider()
			print("Raycast hit: ", collider.name if collider else "None")
			
			if collider and collider.is_in_group("button"):
				print("Button pressed: ", collider.name)
				press_button(collider.name, "right")
				
				# Handle button functionality
				if collider.name == "Button1":
					_on_voyage_selected(1)
				elif collider.name == "Button2":
					print("Quit button pressed")
					# Handle quit functionality
					get_tree().quit()
			
			elif collider and collider.is_in_group("clickable"):
				print("Starting voyage due to trigger click on clickable area")
				_on_voyage_selected(1)

func _on_left_controller_button_pressed(button_name: String):
	if is_changing_scene:
		return
	
	print("Left button pressed: ", button_name)
	if button_name == "trigger_click":
		print("Left trigger click detected")
		
		if left_ray and left_ray.is_colliding():
			var collider = left_ray.get_collider()
			print("Raycast hit: ", collider.name if collider else "None")
			
			if collider and collider.is_in_group("button"):
				print("Button pressed: ", collider.name)
				press_button(collider.name, "left")
				
				# Handle button functionality
				if collider.name == "Button1":
					_on_voyage_selected(1)
				elif collider.name == "Button2":
					print("Quit button pressed")
					# Handle quit functionality
					get_tree().quit()
			
			elif collider and collider.is_in_group("clickable"):
				print("Starting voyage due to trigger click on clickable area")
				_on_voyage_selected(1)

func press_button(button_name: String, controller: String):
	if button_name in buttons:
		# Start button press animation
		active_buttons[button_name] = {
			"timer": 0.0,
			"pressing": true,
			"controller": controller
		}
		
		# Apply haptic feedback for Meta Quest 2 controllers
		if controller == "right" and right_controller:
			right_controller.trigger_haptic_pulse("haptic", 0.5, 0.1, 0.5, 0.0)
		elif controller == "left" and left_controller:
			left_controller.trigger_haptic_pulse("haptic", 0.5, 0.1, 0.5, 0.0)

func _on_voyage_selected(voyage_num: int) -> void:
	if is_changing_scene:
		return
	
	print("Voyage " + str(voyage_num) + " selected")
	is_changing_scene = true
	
	# Set GameManager voyage and difficulty
	var voyage = voyage_data[voyage_num]
	GameManager.set_voyage(voyage_num, voyage["difficulty"])
	GameManager.enemy_spawn_rate = voyage["enemy_spawn_rate"]
	GameManager.enemy_speed = voyage["enemy_speed"]
	GameManager.enemy_health = voyage["enemy_health"]
	
	# Start the campaign
	GameManager.start_campaign()
