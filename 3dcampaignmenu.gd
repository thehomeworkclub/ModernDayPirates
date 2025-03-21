extends Node3D

# Current campaign tracking
var current_campaign = 1
var campaign_sprites = {}
var difficulty_sprite: Sprite3D = null
var flag_sprite: Sprite3D = null

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
var ray_length = 100.0
var normal_ray_color = Color(0, 0.5, 1, 0.6)  # Blue
var hover_ray_color = Color(0, 1, 0, 0.6)     # Green

# Button interaction variables
var buttons = {}
var button_original_positions = {}
var button_press_distance = 0.05
var button_press_duration = 0.15
var active_buttons = {}
var hovering_buttons = {}

# Debug variables
var debug_timer = 0.0
var debug_update_interval = 1.0
var is_changing_scene = false

func _ready() -> void:
	print("\n=== 3D Campaign Menu Initializing ===")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Load campaign sprite sheets
	print("Loading campaign sprite sheets...")
	for i in range(1, 6):
		var texture = load("res://campaignart/campaign_" + str(i) + ".png")
		if texture:
			campaign_sprites[i] = texture
			print("Loaded campaign " + str(i) + " sprite sheet")

	if not _vr_setup_complete:
		setup_vr_environment()

	print("Setting up sprites and references...")
	difficulty_sprite = $DifficultyRange
	flag_sprite = $Flags
	if difficulty_sprite:
		print("Found difficulty range sprite")
	if flag_sprite:
		print("Found flag sprite")

	print("\n=== Setting up VR Controllers ===")
	right_controller = $XROrigin3D/XRController3DRight
	left_controller = $XROrigin3D/XRController3DLeft

	if right_controller:
		print("Found right controller: " + str(right_controller.name))
		right_controller.button_pressed.connect(_on_right_controller_button_pressed)
		print("Connected right controller button signal")
		
		right_ray = right_controller.get_node("RayCastRight")
		if right_ray:
			print("Found right raycast, setting length: " + str(ray_length))
			right_ray.target_position = Vector3(0, 0, -ray_length)
			right_ray.collision_mask = 1  # Ensure ray can see buttons
			print("Right ray collision mask: " + str(right_ray.collision_mask))
		
		right_laser_dot = right_controller.get_node("LaserDotRight")
		if right_laser_dot:
			print("Found right laser dot")
		else:
			print("ERROR: LaserDotRight not found!")

		# Initialize right laser material
		var right_laser = right_controller.get_node("LaserBeamRight")
		if right_laser:
			var material = StandardMaterial3D.new()
			material.flags_transparent = true
			material.albedo_color = normal_ray_color
			material.emission_enabled = true
			material.emission = normal_ray_color
			material.emission_energy = 2.0
			right_laser.material_override = material
			print("Initialized right laser material")
	else:
		print("ERROR: Right controller not found!")

	if left_controller:
		print("Found left controller: " + str(left_controller.name))
		left_controller.button_pressed.connect(_on_left_controller_button_pressed)
		print("Connected left controller button signal")
		
		left_ray = left_controller.get_node("RayCastLeft")
		if left_ray:
			print("Found left raycast, setting length: " + str(ray_length))
			left_ray.target_position = Vector3(0, 0, -ray_length)
			left_ray.collision_mask = 1  # Ensure ray can see buttons
			print("Left ray collision mask: " + str(left_ray.collision_mask))
		
		left_laser_dot = left_controller.get_node("LaserDotLeft")
		if left_laser_dot:
			print("Found left laser dot")
		else:
			print("ERROR: LaserDotLeft not found!")

		# Initialize left laser material
		var left_laser = left_controller.get_node("LaserBeamLeft")
		if left_laser:
			var material = StandardMaterial3D.new()
			material.flags_transparent = true
			material.albedo_color = normal_ray_color
			material.emission_enabled = true
			material.emission = normal_ray_color
			material.emission_energy = 2.0
			left_laser.material_override = material
			print("Initialized left laser material")
	else:
		print("ERROR: Left controller not found!")

	print("\n=== Setting up Interactive Buttons ===")
	setup_interactive_buttons()
	
	update_campaign_map()
	update_indicators()
	
	set_process_input(true)
	set_process(true)
	print("\n=== Setup Complete ===")
	print("VR Debug: XR Interface Active = " + str(XRServer.primary_interface != null))

func _process(delta: float) -> void:
	debug_timer += delta
	update_laser_pointers()
	update_button_hover_states()
	update_button_animations(delta)

	if debug_timer >= debug_update_interval:
		debug_timer = 0.0
		if right_ray and right_ray.is_colliding():
			var collider = right_ray.get_collider()
			print("Right ray collision point: " + str(right_ray.get_collision_point()))
			print("Right ray collision normal: " + str(right_ray.get_collision_normal()))
			if collider:
				print("Right ray hit: " + collider.name)
		if left_ray and left_ray.is_colliding():
			var collider = left_ray.get_collider()
			print("Left ray collision point: " + str(left_ray.get_collision_point()))
			print("Left ray collision normal: " + str(left_ray.get_collision_normal()))
			if collider:
				print("Left ray hit: " + collider.name)

func _on_right_controller_button_pressed(button_name: String):
	print("\nRight Controller Button Event: " + button_name)
	if is_changing_scene:
		return
		
	if button_name == "trigger_click":
		print("Right trigger clicked")
		if right_ray and right_ray.is_colliding():
			var collider = right_ray.get_collider()
			print("Right ray hit: " + str(collider.name if collider else "None"))
			if collider and collider.is_in_group("button"):
				print("Pressing button: " + collider.name)
				press_button(collider.name, "right")

func _on_left_controller_button_pressed(button_name: String):
	print("\nLeft Controller Button Event: " + button_name)
	if is_changing_scene:
		return
		
	if button_name == "trigger_click":
		print("Left trigger clicked")
		if left_ray and left_ray.is_colliding():
			var collider = left_ray.get_collider()
			print("Left ray hit: " + str(collider.name if collider else "None"))
			if collider and collider.is_in_group("button"):
				print("Pressing button: " + collider.name)
				press_button(collider.name, "left")

func update_laser_pointers():
	# Update right controller laser
	if right_ray and right_laser_dot:
		var right_laser = right_controller.get_node("LaserBeamRight")
		if right_laser:
			var material = right_laser.material_override
			if material:
				if right_ray.is_colliding():
					var collision_point = right_ray.get_collision_point()
					var collider = right_ray.get_collider()
					
					right_laser_dot.global_position = collision_point
					right_laser_dot.visible = true
					
					if collider and collider.is_in_group("button"):
						material.albedo_color = hover_ray_color
						material.emission = hover_ray_color
					else:
						material.albedo_color = normal_ray_color
						material.emission = normal_ray_color
				else:
					material.albedo_color = normal_ray_color
					material.emission = normal_ray_color
					right_laser_dot.visible = false

	# Update left controller laser
	if left_ray and left_laser_dot:
		var left_laser = left_controller.get_node("LaserBeamLeft")
		if left_laser:
			var material = left_laser.material_override
			if material:
				if left_ray.is_colliding():
					var collision_point = left_ray.get_collision_point()
					var collider = left_ray.get_collider()
					
					left_laser_dot.global_position = collision_point
					left_laser_dot.visible = true
					
					if collider and collider.is_in_group("button"):
						material.albedo_color = hover_ray_color
						material.emission = hover_ray_color
					else:
						material.albedo_color = normal_ray_color
						material.emission = normal_ray_color
				else:
					material.albedo_color = normal_ray_color
					material.emission = normal_ray_color
					left_laser_dot.visible = false

func update_button_hover_states():
	# Clear previous hover states
	hovering_buttons.clear()
	
	# Check right controller
	if right_ray and right_ray.is_colliding():
		var collider = right_ray.get_collider()
		if collider and collider.is_in_group("button"):
			hovering_buttons[collider.name] = "right"
			print_verbose("Right hovering: " + collider.name)
			print_verbose("Collision point: " + str(right_ray.get_collision_point()))

	# Check left controller
	if left_ray and left_ray.is_colliding():
		var collider = left_ray.get_collider()
		if collider and collider.is_in_group("button"):
			hovering_buttons[collider.name] = "left"
			print_verbose("Left hovering: " + collider.name)
			print_verbose("Collision point: " + str(left_ray.get_collision_point()))

func setup_interactive_buttons():
	print("\n=== Setting up Interactive Buttons ===")
	
	# Disable clickable area collision if it exists
	var clickable_area = $MapDisplay/ClickableArea if has_node("MapDisplay/ClickableArea") else null
	if clickable_area:
		if clickable_area.has_node("CollisionShape3D"):
			var collision = clickable_area.get_node("CollisionShape3D")
			collision.disabled = true
			print("Disabled map clickable area collision")
	
	# Process buttons
	for child in get_children():
		if "Button" in child.name:
			print("\nProcessing button: " + child.name)
			print("Node type: " + child.get_class())
			print("Global position: " + str(child.global_position))
			print("Local position: " + str(child.position))
			
			# Ensure collision is set up properly
			if child is Area3D:
				print("Node is Area3D - Setting up monitoring")
				child.monitorable = true
				child.monitoring = true
			elif child is StaticBody3D:
				print("Node is StaticBody3D")
			
			# Ensure the node is in the button group
			if not child.is_in_group("button"):
				print("Adding " + child.name + " to button group")
				child.add_to_group("button")
			else:
				print(child.name + " already in button group")
			
			# Get and verify the button mesh
			var button_mesh = child.get_node("ButtonMesh")
			if button_mesh:
				print("Found button mesh for: " + child.name)
				buttons[child.name] = button_mesh
				button_original_positions[child.name] = button_mesh.position
				
				# Get mesh size for collision shape
				var mesh_aabb = button_mesh.get_aabb()
				print("Button mesh AABB:")
				print("  Size: " + str(mesh_aabb.size))
				print("  Position: " + str(mesh_aabb.position))
				print("  Center: " + str(mesh_aabb.get_center()))
			else:
				print("ERROR: No ButtonMesh found for " + child.name)

			# Verify and setup collision shape
			var collision = child.get_node("CollisionShape3D")
			if collision:
				print("Found collision shape for " + child.name)
				collision.disabled = false
				child.collision_layer = 1
				child.collision_mask = 1
				
				var shape = collision.shape
				if shape:
					print("Collision shape details:")
					print("  Type: " + str(shape.get_class()))
					if shape is BoxShape3D:
						var size = shape.size
						print("  Box size: " + str(size))
						
						# Ensure box encompasses entire button
						if button_mesh:
							var mesh_aabb = button_mesh.get_aabb()
							if size.y < mesh_aabb.size.y:
								print("WARNING: Collision height smaller than mesh!")
								shape.size.y = mesh_aabb.size.y
								print("  Adjusted box height to: " + str(shape.size.y))
					
					elif shape is CylinderShape3D:
						print("  Cylinder height: " + str(shape.height))
						print("  Cylinder radius: " + str(shape.radius))
						
						# Ensure cylinder encompasses entire button
						if button_mesh:
							var mesh_aabb = button_mesh.get_aabb()
							if shape.height < mesh_aabb.size.y:
								print("WARNING: Collision height smaller than mesh!")
								shape.height = mesh_aabb.size.y
								print("  Adjusted cylinder height to: " + str(shape.height))

					print("  Global position: " + str(collision.global_position))
					print("  Local position: " + str(collision.position))

					# Adjust collision position if needed
					if button_mesh:
						var mesh_aabb = button_mesh.get_aabb()
						var mesh_center = mesh_aabb.get_center()
						print("  Mesh center: " + str(mesh_center))
						
						# Only adjust if significantly off-center
						if mesh_center.length() > 0.01:
							var old_pos = collision.position
							collision.position = Vector3(
								collision.position.x,
								collision.position.y + mesh_aabb.size.y/2,
								collision.position.z
							)
							print("  Adjusted collision position:")
							print("    From: " + str(old_pos))
							print("    To: " + str(collision.position))
			else:
				print("ERROR: No CollisionShape3D found for " + child.name)

func press_button(button_name: String, controller: String):
	print("\nButton Press Handler:")
	print("Button: " + button_name + " | Controller: " + controller)
	
	if button_name in buttons:
		print("Valid button found: " + button_name)
		
		# Start button press animation
		active_buttons[button_name] = {
			"timer": 0.0,
			"pressing": true,
			"controller": controller
		}
		print("Started button animation")

		# Apply haptic feedback
		if controller == "right" and right_controller:
			print("Right controller haptic")
			right_controller.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)
		elif controller == "left" and left_controller:
			print("Left controller haptic")
			left_controller.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)

		# Handle button actions
		match button_name:
			"ShopButton":
				print("Shop button pressed - Opening shop")
				# TODO: Implement shop functionality
			"StartButton":
				print("Start button pressed - Starting voyage")
				_on_voyage_selected(current_campaign)
			"ExitButton":
				print("Exit button pressed - Forcing quit")
				OS.kill(OS.get_process_id())
			_:
				print("ERROR: Unknown button: " + button_name)
	else:
		print("ERROR: Invalid button name: " + button_name)

func update_button_animations(delta):
	var buttons_to_remove = []
	for button_name in active_buttons.keys():
		var button_info = active_buttons[button_name]
		button_info.timer += delta

		if button_info.timer <= button_press_duration:
			var t = button_info.timer / button_press_duration
			var button_mesh = buttons[button_name]
			var original_pos = button_original_positions[button_name]

			if button_info.pressing:
				var target_pos = original_pos - Vector3(0, button_press_distance, 0)
				button_mesh.position = original_pos.lerp(target_pos, t)
			else:
				var current_pos = button_mesh.position
				var target_pos = original_pos
				button_mesh.position = current_pos.lerp(target_pos, t)
		else:
			if not button_info.pressing:
				buttons_to_remove.append(button_name)
				buttons[button_name].position = button_original_positions[button_name]
			else:
				button_info.pressing = false
				button_info.timer = 0

	for button_name in buttons_to_remove:
		active_buttons.erase(button_name)

func setup_vr_environment() -> void:
	print("\n=== Setting up VR Environment ===")
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("Found OpenXR interface, initializing...")
		xr_interface.initialize()
		get_viewport().use_xr = true
		_vr_setup_complete = true

		var origin = $XROrigin3D if has_node("XROrigin3D") else null
		if origin:
			print("Found XR Origin, setting position: " + str(vr_position))
			origin.position = vr_position
			if origin.has_node("XRCamera3D"):
				var camera = origin.get_node("XRCamera3D")
				print("Setting camera height: " + str(vr_camera_height))
				camera.position.y = vr_camera_height
				camera.look_at(vr_look_at)
			else:
				print("ERROR: XRCamera3D not found!")
		else:
			print("ERROR: XROrigin3D not found!")
	else:
		print("ERROR: OpenXR interface not found!")

func _on_voyage_selected(voyage_num: int) -> void:
	if is_changing_scene:
		print("Scene already changing, ignoring selection")
		return

	print("\n=== Starting Voyage " + str(voyage_num) + " ===")
	is_changing_scene = true

	# Update current campaign
	current_campaign = voyage_num
	print("Setting campaign to: " + str(current_campaign))
	update_indicators()

	# Get voyage data
	var voyage = voyage_data[voyage_num]
	print("Loading voyage settings:")
	print("Name: " + voyage["name"])
	print("Difficulty: " + voyage["difficulty"])
	print("Enemy Spawn Rate: " + str(voyage["enemy_spawn_rate"]))
	print("Enemy Speed: " + str(voyage["enemy_speed"]))
	print("Enemy Health: " + str(voyage["enemy_health"]))

	# Configure game settings
	GameManager.set_voyage(voyage_num, voyage["difficulty"])
	GameManager.enemy_spawn_rate = voyage["enemy_spawn_rate"]
	GameManager.enemy_speed = voyage["enemy_speed"]
	GameManager.enemy_health = voyage["enemy_health"]

	print("Starting campaign...")
	GameManager.start_campaign()

func update_indicators() -> void:
	print("\n=== Updating Campaign Indicators ===")
	if difficulty_sprite and flag_sprite:
		# Calculate frame sizes
		var difficulty_texture = difficulty_sprite.texture
		var difficulty_frame_width = difficulty_texture.get_width() / 5
		var difficulty_frame_height = difficulty_texture.get_height()
		print("Difficulty frame size: " + str(difficulty_frame_width) + "x" + str(difficulty_frame_height))

		var flag_texture = flag_sprite.texture
		var flag_frame_width = flag_texture.get_width() / 5
		var flag_frame_height = flag_texture.get_height()
		print("Flag frame size: " + str(flag_frame_width) + "x" + str(flag_frame_height))

		# Update indicators
		difficulty_sprite.region_enabled = true
		difficulty_sprite.region_rect = Rect2(
			(current_campaign - 1) * difficulty_frame_width,
			0,
			difficulty_frame_width,
			difficulty_frame_height
		)
		print("Set difficulty region: " + str(difficulty_sprite.region_rect))

		flag_sprite.region_enabled = true
		flag_sprite.region_rect = Rect2(
			(current_campaign - 1) * flag_frame_width,
			0,
			flag_frame_width,
			flag_frame_height
		)
		print("Set flag region: " + str(flag_sprite.region_rect))
	else:
		print("ERROR: Missing sprite references!")
		if not difficulty_sprite:
			print("Difficulty sprite not found!")
		if not flag_sprite:
			print("Flag sprite not found!")

func set_campaign(campaign_num: int) -> void:
	if campaign_num < 1 or campaign_num > 5:
		print("ERROR: Invalid campaign number: " + str(campaign_num))
		return

	print("\n=== Switching to Campaign " + str(campaign_num) + " ===")
	current_campaign = campaign_num
	
	# Update visuals
	update_campaign_map()
	update_indicators()

func update_campaign_map() -> void:
	print("\n=== Updating Campaign Map ===")
	if current_campaign in campaign_sprites:
		var sprite_node = $MapDisplay/AnimatedSprite3D
		if sprite_node:
			var texture = campaign_sprites[current_campaign]
			print("Loading campaign " + str(current_campaign) + " texture")

			# Set up animation frames
			var frames = SpriteFrames.new()
			frames.remove_animation("default")
			frames.add_animation("default")
			frames.set_animation_loop("default", true)
			frames.set_animation_speed("default", 5.0)

			# Calculate frame dimensions
			var frame_width = texture.get_width() / 6  # 6 frames per animation
			var frame_height = texture.get_height()
			print("Frame size: " + str(frame_width) + "x" + str(frame_height))

			# Add frames to animation
			for i in range(6):
				var atlas = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
				frames.add_frame("default", atlas)
				print("Added frame " + str(i + 1))

			# Update and play animation
			sprite_node.sprite_frames = frames
			sprite_node.play()
			print("Started map animation")
		else:
			print("ERROR: AnimatedSprite3D not found in MapDisplay!")
	else:
		print("ERROR: Campaign " + str(current_campaign) + " sprite not found!")
