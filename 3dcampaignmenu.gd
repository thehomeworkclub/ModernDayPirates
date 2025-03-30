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
var buttons = {
	"ShopButton": null,
	"StartButton": null,
	"ExitButton": null
}
var button_original_positions = {}
var button_press_distance = 0.05
var button_press_duration = 0.15
var active_buttons = {}
var hovering_buttons = {}

# Button mesh nodes
@onready var shop_button = $ShopButton
@onready var start_button = $StartButton
@onready var exit_button = $ExitButton

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
	
	setup_vr_controllers()
	setup_interactive_buttons()
	update_campaign_map()
	update_indicators()
	
	set_process_input(true)
	set_process(true)
	print("\n=== Setup Complete ===")
	print("VR Debug: XR Interface Active = " + str(XRServer.primary_interface != null))

func setup_vr_controllers():
	print("\n=== Setting up VR Controllers ===")
	right_controller = $XROrigin3D/XRController3DRight
	left_controller = $XROrigin3D/XRController3DLeft
	
	if right_controller:
		print("Found right controller: " + str(right_controller.name))
		right_controller.button_pressed.connect(_on_right_controller_button_pressed)
		setup_controller(right_controller, "right")
	
	if left_controller:
		print("Found left controller: " + str(left_controller.name))
		left_controller.button_pressed.connect(_on_left_controller_button_pressed)
		setup_controller(left_controller, "left")

func setup_controller(controller: XRController3D, side: String):
	var ray = controller.get_node("RayCast" + side.capitalize())
	if ray:
		print("Found " + side + " raycast, setting length: " + str(ray_length))
		ray.target_position = Vector3(0, 0, -ray_length)
		ray.collision_mask = 1
		if side == "right":
			right_ray = ray
		else:
			left_ray = ray
	
	var laser_dot = controller.get_node("LaserDot" + side.capitalize())
	if laser_dot:
		print("Found " + side + " laser dot")
		if side == "right":
			right_laser_dot = laser_dot
		else:
			left_laser_dot = laser_dot
	
	var laser = controller.get_node("LaserBeam" + side.capitalize())
	if laser:
		setup_laser_material(laser)
	else:
		print("ERROR: " + side + " laser not found!")

func setup_laser_material(laser: MeshInstance3D):
	var material = StandardMaterial3D.new()
	material.flags_transparent = true
	material.albedo_color = normal_ray_color
	material.emission_enabled = true
	material.emission = normal_ray_color
	material.emission_energy = 2.0
	laser.material_override = material
	print("Initialized laser material")

func _on_right_controller_button_pressed(button_name: String):
	if is_changing_scene or button_name != "trigger_click":
		return
	
	if right_ray and right_ray.is_colliding():
		var collider = right_ray.get_collider()
		if collider and collider.is_in_group("button"):
			press_button(collider.name, "right")

func _on_left_controller_button_pressed(button_name: String):
	if is_changing_scene or button_name != "trigger_click":
		return
	
	if left_ray and left_ray.is_colliding():
		var collider = left_ray.get_collider()
		if collider and collider.is_in_group("button"):
			press_button(collider.name, "left")

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
	
	# Configure game settings
	print("Setting voyage with difficulty: ", voyage["difficulty"])
	GameManager.set_voyage(voyage_num, voyage["difficulty"])
	
	print("Starting campaign...")
	GameManager.start_campaign()

func update_laser_pointers():
	update_laser(right_ray, right_laser_dot, "right")
	update_laser(left_ray, left_laser_dot, "left")

func update_laser(ray: RayCast3D, laser_dot: MeshInstance3D, side: String):
	if not (ray and laser_dot):
		return
	
	var laser = get_node("XROrigin3D/XRController3D" + side.capitalize() + "/LaserBeam" + side.capitalize())
	if laser and laser.material_override:
		var material = laser.material_override
		if ray.is_colliding():
			var collision_point = ray.get_collision_point()
			var collider = ray.get_collider()
			
			laser_dot.global_position = collision_point
			laser_dot.visible = true
			
			material.albedo_color = hover_ray_color if collider and collider.is_in_group("button") else normal_ray_color
			material.emission = material.albedo_color
		else:
			material.albedo_color = normal_ray_color
			material.emission = normal_ray_color
			laser_dot.visible = false

func update_button_hover_states():
	hovering_buttons.clear()
	
	check_ray_hover(right_ray, "right")
	check_ray_hover(left_ray, "left")

func check_ray_hover(ray: RayCast3D, side: String):
	if ray and ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.is_in_group("button"):
			hovering_buttons[collider.name] = side

func setup_interactive_buttons():
	print("\n=== Setting up Interactive Buttons ===")
	
	# Disable clickable area collision if it exists
	var clickable_area = $MapDisplay/ClickableArea if has_node("MapDisplay/ClickableArea") else null
	if clickable_area and clickable_area.has_node("CollisionShape3D"):
		clickable_area.get_node("CollisionShape3D").disabled = true
	
	if shop_button and start_button and exit_button:
		var button_nodes = {
			"ShopButton": shop_button,
			"StartButton": start_button,
			"ExitButton": exit_button
		}
		
		for button_name in button_nodes:
			setup_button(button_nodes[button_name], button_name)

func setup_button(button: Node3D, button_name: String):
	if not button.is_in_group("button"):
		button.add_to_group("button")
	
	var button_mesh = button.get_node("ButtonMesh")
	if not button_mesh:
		button_mesh = button.get_node("Sprite3D")
	
	if button_mesh:
		buttons[button_name] = button_mesh
		button_original_positions[button_name] = button_mesh.position
		
		var collision = button.get_node("CollisionShape3D")
		if collision:
			collision.disabled = false
			button.collision_layer = 1
			button.collision_mask = 1

func press_button(button_name: String, controller: String):
	if not button_name in buttons:
		return
	
	active_buttons[button_name] = {
		"timer": 0.0,
		"pressing": true,
		"controller": controller
	}
	
	# Apply haptic feedback
	var controller_node = get_node("XROrigin3D/XRController3D" + controller.capitalize())
	if controller_node:
		controller_node.trigger_haptic_pulse("haptic", 0.8, 0.15, 0.7, 0.0)
	
	# Handle button actions
	match button_name:
		"ShopButton":
			is_changing_scene = true
			get_tree().change_scene_to_file("res://shop1.tscn")
		"StartButton":
			_on_voyage_selected(current_campaign)
		"ExitButton":
			OS.kill(OS.get_process_id())

func update_button_animations(delta: float):
	var buttons_to_remove = []
	
	for button_name in active_buttons:
		var button_info = active_buttons[button_name]
		button_info.timer += delta
		
		if button_info.timer <= button_press_duration:
			animate_button(button_name, button_info)
		else:
			if not button_info.pressing:
				buttons_to_remove.append(button_name)
				reset_button_position(button_name)
			else:
				button_info.pressing = false
				button_info.timer = 0
	
	for button_name in buttons_to_remove:
		active_buttons.erase(button_name)

func animate_button(button_name: String, button_info: Dictionary):
	var t = button_info.timer / button_press_duration
	var button_mesh = buttons[button_name]
	var original_pos = button_original_positions[button_name]
	
	if button_info.pressing:
		var target_pos = original_pos - Vector3(0, button_press_distance, 0)
		button_mesh.position = original_pos.lerp(target_pos, t)
	else:
		var current_pos = button_mesh.position
		button_mesh.position = current_pos.lerp(original_pos, t)

func reset_button_position(button_name: String):
	buttons[button_name].position = button_original_positions[button_name]

func setup_vr_environment() -> void:
	print("\n=== Setting up VR Environment ===")
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		xr_interface.initialize()
		get_viewport().use_xr = true
		_vr_setup_complete = true
		
		var origin = $XROrigin3D
		if origin:
			origin.position = vr_position
			var camera = origin.get_node("XRCamera3D")
			if camera:
				camera.position.y = vr_camera_height
				camera.look_at(vr_look_at)

func update_indicators() -> void:
	if not (difficulty_sprite and flag_sprite):
		return
	
	var difficulty_texture = difficulty_sprite.texture
	var difficulty_frame_width = difficulty_texture.get_width() / 5
	
	var flag_texture = flag_sprite.texture
	var flag_frame_width = flag_texture.get_width() / 5
	
	update_sprite_region(difficulty_sprite, difficulty_frame_width)
	update_sprite_region(flag_sprite, flag_frame_width)

func update_sprite_region(sprite: Sprite3D, frame_width: float):
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		(current_campaign - 1) * frame_width,
		0,
		frame_width,
		sprite.texture.get_height()
	)

func set_campaign(campaign_num: int) -> void:
	if campaign_num < 1 or campaign_num > 5:
		return
	
	current_campaign = campaign_num
	update_campaign_map()
	update_indicators()

func update_campaign_map() -> void:
	if not current_campaign in campaign_sprites:
		return
	
	var sprite_node = $MapDisplay/AnimatedSprite3D
	if not sprite_node:
		return
	
	var texture = campaign_sprites[current_campaign]
	var frames = create_sprite_frames(texture)
	
	sprite_node.sprite_frames = frames
	sprite_node.play()

func create_sprite_frames(texture: Texture2D) -> SpriteFrames:
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("default")
	frames.set_animation_loop("default", true)
	frames.set_animation_speed("default", 5.0)
	
	var frame_width = texture.get_width() / 6
	
	for i in range(6):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, texture.get_height())
		frames.add_frame("default", atlas)
	
	return frames

func _process(delta: float) -> void:
	debug_timer += delta
	update_laser_pointers()
	update_button_hover_states()
	update_button_animations(delta)
	
	if debug_timer >= debug_update_interval:
		debug_timer = 0.0
		debug_update()

func debug_update():
	if right_ray and right_ray.is_colliding():
		var collider = right_ray.get_collider()
		if collider:
			print("Right ray hit: " + collider.name)
	
	if left_ray and left_ray.is_colliding():
		var collider = left_ray.get_collider()
		if collider:
			print("Left ray hit: " + collider.name)
