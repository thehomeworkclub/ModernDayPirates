extends Node

# Time in seconds player spends in the shop
var shop_time_remaining = 15.0
@onready var transition = $"/root/SceneTransition" if has_node("/root/SceneTransition") else null

func _ready():
	print("Shop timer initialized. Player has 15 seconds in the shop.")
	# Preload the SceneTransition if it doesn't exist
	if not transition:
		var scene_transition = load("res://SceneTransition.tscn").instantiate()
		get_tree().root.add_child(scene_transition)
		transition = scene_transition

func _process(delta):
	# Count down the timer
	shop_time_remaining -= delta
	
	# When time expires, return to level1
	if shop_time_remaining <= 0:
		print("Shop time expired. Returning to level1.")
		
		# If we have the transition manager, use it for smooth transition
		if transition:
			transition.change_scene_with_fade("res://level1.tscn")
		else:
			# Fallback direct scene change
			get_tree().change_scene_to_file("res://level1.tscn")
