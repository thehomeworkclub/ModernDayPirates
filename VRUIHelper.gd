extends Node

# VRUIHelper - Makes UI elements interact with 3D raycasts in VR
# This script should be attached to the main scene

# Store references to all active UI elements
var ui_elements = []

# Debug variables
var debug_mode = true

func _ready():
	print("VRUIHelper: Initializing UI interaction system for VR")
	
	# Wait a frame to ensure all UI is loaded
	await get_tree().process_frame
	
	# Find all UI elements and make them raycast-able
	configure_ui_for_raycast()
	
	# Connect to scene tree changed signal to catch any new UI elements
	get_tree().node_added.connect(_on_node_added)
	
	# Add extra debugging
	if debug_mode:
		print("VRUIHelper: Debug mode enabled")
		print("VRUIHelper: OpenXR active = " + str(XRServer.primary_interface != null))
		
		# Set up a debug timer to report UI elements and raycast status
		var debug_timer = Timer.new()
		debug_timer.wait_time = 3.0  # Check every 3 seconds
		debug_timer.one_shot = false
		debug_timer.autostart = true
		debug_timer.timeout.connect(_debug_report)
		add_child(debug_timer)

func _debug_report():
	if debug_mode:
		print("VRUIHelper: Currently tracking " + str(ui_elements.size()) + " UI elements")
		
		# Check for controllers and raycasts
		var right_controller = get_viewport().get_camera_3d().get_parent().get_parent().find_child("XRController3DRight")
		if right_controller:
			print("VRUIHelper: Right controller found at " + str(right_controller.global_transform.origin))
			var ray = right_controller.find_child("RayCast3D")
			if ray and ray is RayCast3D:
				print("VRUIHelper: Controller raycast is present")
				if ray.is_colliding():
					print("VRUIHelper: Ray is hitting: " + str(ray.get_collider().name))
			else:
				print("VRUIHelper: WARNING - Controller raycast not found")
		else:
			print("VRUIHelper: WARNING - Right controller not found")

func configure_ui_for_raycast():
	# Find all UI elements currently in the scene
	find_ui_elements(get_tree().root)
	
	# Configure each for raycast interaction
	for ui in ui_elements:
		make_raycast_able(ui)
	
	print("VRUIHelper: Configured ", ui_elements.size(), " UI elements for raycast")

func find_ui_elements(node):
	# Check if this node is a UI element
	if node is Control:
		if not ui_elements.has(node):
			ui_elements.append(node)
	
	# Process children recursively
	for child in node.get_children():
		find_ui_elements(child)

func make_raycast_able(ui_element):
	# Ensure the UI element has mouse filter set to STOP
	ui_element.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# For buttons and interactive elements, add click handling if needed
	if ui_element is Button or ui_element is TextureButton:
		# Ensure button is configured properly
		ui_element.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# Make buttons slightly larger for easier selection in VR
		if ui_element.size.x < 40 or ui_element.size.y < 40:
			ui_element.custom_minimum_size = Vector2(max(ui_element.custom_minimum_size.x, 40), 
											max(ui_element.custom_minimum_size.y, 40))
	
	# For sliders and other draggable controls
	if ui_element is Slider or ui_element is ScrollContainer:
		ui_element.mouse_default_cursor_shape = Control.CURSOR_MOVE
		
	# Special handling for ClickableArea3D
	if "ClickableArea" in ui_element.name and ui_element is Area3D:
		ui_element.add_to_group("clickable")
		if debug_mode:
			print("VRUIHelper: Added " + ui_element.name + " to clickable group")

func _on_node_added(node):
	# If a UI element is added dynamically, configure it for raycast
	if node is Control:
		if not ui_elements.has(node):
			ui_elements.append(node)
			make_raycast_able(node)
			
			# If this is a container, process its children
			for child in node.get_children():
				_on_node_added(child)
				
	# Special handling for 3D clickable areas
	if node is Area3D and "ClickableArea" in node.name:
		node.add_to_group("clickable")
		if debug_mode:
			print("VRUIHelper: Added dynamic " + node.name + " to clickable group")
