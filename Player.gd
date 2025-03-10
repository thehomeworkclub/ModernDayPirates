extends Node3D

@export var mouse_sensitivity: float = 0.1
var pitch: float = 0.0
var mouse_captured: bool = true
var health: int = 100  # Add health to player

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready() -> void:
	# Start with mouse captured for gameplay
	capture_mouse()
	
	# CRITICAL: Add to Player group for targeting
	add_to_group("Player")
	
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
	
	if health <= 0:
		print("DEBUG: Player health depleted!")
		health = 1  # Keep player alive with minimum health
	else:
		print("DEBUG: Player health remaining: " + str(health))
