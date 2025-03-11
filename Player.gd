extends Node3D

@export var mouse_sensitivity: float = 0.1
var pitch: float = 0.0
var mouse_captured: bool = true
var max_health: int = 10  # Changed to match UI's health display
var health: int = max_health  # Set initial health to max

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready() -> void:
	# Start with mouse captured for gameplay
	capture_mouse()
	
	# CRITICAL: Add to Player group for targeting
	add_to_group("Player")
	
	# Reset health on spawn/respawn
	reset_health()

	# Add this to your main scene's _ready() function
	var ui_canvas = CanvasLayer.new()
	ui_canvas.name = "UICanvasLayer"
	add_child(ui_canvas)
		
	# Make sure we're not at the origin (0,0,0)
	if global_position == Vector3.ZERO:
		# Use the original transform position from the scene
		var expected_position = Vector3(0, 7.24827, -30.0)
		global_position = expected_position
		print("DEBUG: Fixed player position to ", global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		# Rotate Player left/right (yaw).
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		# Rotate Head up/down (pitch), clamped so you can't flip upside down.
		pitch = clamp(pitch + event.relative.y * mouse_sensitivity, -90, 90)
		head.rotation_degrees.x = pitch
	
	# Toggle mouse capture with Escape key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_capture()

# Toggle between captured and free mouse modes
func toggle_mouse_capture() -> void:
	if mouse_captured:
		release_mouse()
	else:
		capture_mouse()

# Release mouse for UI interaction
func release_mouse() -> void:
	mouse_captured = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("DEBUG: Mouse released for UI interaction")

# Capture mouse for gameplay
func capture_mouse() -> void:
	mouse_captured = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("DEBUG: Mouse captured for gameplay")
	
# Add take_damage method to Player - but never destroy the player
func take_damage(amount: int) -> void:
	print("DEBUG: Player took " + str(amount) + " damage!")
	health -= amount
	var health_bar = create_health_bar()
	health_bar.add_to_group("HealthBar")

	if health <= 0:
		print("DEBUG: Player health depleted!")
		health = 1  # Keep player alive with minimum health
	else:
		print("DEBUG: Player health remaining: " + str(health))

# In Player.gd's reset_health function
func reset_health() -> void:
	health = max_health
	print("DEBUG: Player health reset to ", health)
	
	# Remove old health bars
	var old_bars = get_tree().get_nodes_in_group("HealthBar")
	for bar in old_bars:
		bar.queue_free()
	
	# Create and position new health bar with safety checks
	var new_health_bar = create_health_bar()
	new_health_bar.add_to_group("HealthBar")
	
	# Get main UI container safely
	var ui_layer = get_tree().current_scene.find_child("UICanvasLayer", true, false)
	if ui_layer:
		ui_layer.add_child(new_health_bar)
	else:
		print("WARNING: No UI layer found, adding health bar directly to scene")
		get_tree().current_scene.add_child(new_health_bar)

func create_health_bar() -> Control:
	var health_bar = ProgressBar.new()
	health_bar.name = "PlayerHealthBar"
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.size = Vector2(200, 20)
	health_bar.position = Vector2(20, 20)
	return health_bar
