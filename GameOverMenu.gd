extends Control

# Simple red fade overlay for game over
var fade_timer: float = 0.0
var fade_duration: float = 2.0
var is_fading: bool = true

func _ready() -> void:
	# Simplify the UI - just a full-screen red overlay that fades in
	# Create a ColorRect if it doesn't exist
	if not has_node("RedOverlay"):
		var overlay = ColorRect.new()
		overlay.name = "RedOverlay"
		overlay.color = Color(1, 0, 0, 0)  # Start fully transparent
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
	# Return to 3D campaign menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://3dcampaignmenu.tscn")
	queue_free()
