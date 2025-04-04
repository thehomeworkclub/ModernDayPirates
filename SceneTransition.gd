extends CanvasLayer

signal transition_completed

@onready var animation_player = $AnimationPlayer
@onready var black_rect = $ColorRect

# Called when the node enters the scene tree for the first time
func _ready():
	# Ensure the ColorRect is invisible at the start
	black_rect.color = Color(0, 0, 0, 0)

# Fade to black
func fade_to_black():
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	emit_signal("transition_completed")

# Fade from black
func fade_from_black():
	animation_player.play("fade_from_black")
	await animation_player.animation_finished
	emit_signal("transition_completed")

# Change scene with fade effect
func change_scene_with_fade(target_scene: String):
	# Fade to black first
	fade_to_black()
	await transition_completed
	
	# Change scene
	var err = get_tree().change_scene_to_file(target_scene)
	if err != OK:
		print("ERROR: Failed to change scene to: " + target_scene)
	
	# Fade from black
	fade_from_black()
