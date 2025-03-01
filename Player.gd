extends Node3D

@export var mouse_sensitivity: float = 0.1
var pitch: float = 0.0
var mouse_captured: bool = true

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready() -> void:
	# Start with mouse captured for gameplay
	capture_mouse()

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
