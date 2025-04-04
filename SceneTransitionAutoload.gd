extends Node

var transition_scene: Node = null

func _ready():
	# Create the transition scene on game startup
	transition_scene = load("res://SceneTransition.tscn").instantiate()
	add_child(transition_scene)
	
	print("Scene transition system initialized")

# Get the transition scene
func get_transition():
	return transition_scene
	
# Convenience method for scene changes with fade
func change_scene_with_fade(target_scene: String):
	if transition_scene:
		transition_scene.change_scene_with_fade(target_scene)
	else:
		print("ERROR: Transition scene not available")
		get_tree().change_scene_to_file(target_scene)
