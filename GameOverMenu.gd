extends Control

# Dark red fade overlay for game over
var fade_timer: float = 0.0
var fade_duration: float = 2.0
var is_fading: bool = true

func _ready() -> void:
	# Set process to run _process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Make sure the game is paused
	get_tree().paused = true
	
	# Reset GameManager to round 1
	if GameManager:
		GameManager.current_round = 1
		print("DEBUG: GameManager reset to round 1 in GameOverMenu")
	
	# Simplify the UI - just a full-screen dark red overlay that fades in
	if not has_node("RedOverlay"):
		var overlay = ColorRect.new()
		overlay.name = "RedOverlay"
		overlay.color = Color(0.5, 0, 0, 0)  # Start with dark red, fully transparent
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 1.0
		add_child(overlay)
	
	# Start the return to menu timer
	var timer = Timer.new()
	timer.name = "MenuTimer"
	timer.wait_time = fade_duration
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_return_to_campaign_menu)

func _process(delta: float) -> void:
	if is_fading:
		fade_timer += delta
		var alpha = min(fade_timer / fade_duration, 1.0)
		$RedOverlay.color.a = alpha

func _return_to_campaign_menu() -> void:
	print("DEBUG: Returning to campaign menu after game over")
	
	# Unpause game before changing scenes
	get_tree().paused = false
	
	# Return to 3D campaign menu
	var result = get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")
	if result != OK:
		print("ERROR: Failed to change to campaign menu scene")
	
	# Clean up this menu
	queue_free()
