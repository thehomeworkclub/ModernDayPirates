# BoatSpawner.gd
extends Node3D

# Export a NodePath so you can assign your player boat from the editor.
@export var player_boat_path: NodePath
var player_boat: Node3D

# Preload the enemy boat scene (make sure the path matches your project structure).

var enemy_boat_scene: PackedScene = preload("res://EnemyBoat.tscn")
func _ready() -> void:
	# Retrieve the player's boat using the provided NodePath.
	player_boat = get_node(player_boat_path) as Node3D
	if player_boat == null:
		push_error("Player boat is nil! Check that the Player Boat Path is set correctly in the Inspector.")
	else:
		print("Player boat found: ", player_boat.name)
	
	# Option 1: Immediately spawn one enemy boat for testing.
	call_deferred("spawn_enemy_boat")
	
	# Option 2: Connect the Timer node's timeout signal to continuously spawn boats.
	if has_node("Timer"):
		$Timer.timeout.connect(_on_Timer_timeout)

func spawn_enemy_boat() -> void:
	# Instance a new enemy boat from the preloaded scene.
	var enemy_boat: CharacterBody3D = enemy_boat_scene.instantiate() as CharacterBody3D
	
	# Define how far from the player's boat the enemy boat should appear.
	var spawn_distance: float = 100.0  # Adjust this value as needed.
	
	# Calculate the spawn position relative to the player's boat.
	# This example spawns the enemy boat to the right of the player's boat.
	var spawn_position: Vector3 = player_boat.global_transform.origin + Vector3(spawn_distance, 0, 0)
	enemy_boat.global_transform.origin = spawn_position
	
	# Add the enemy boat as a child of the main scene (or this spawner node).
	get_tree().current_scene.add_child(enemy_boat)
	
	# Call the enemy boat’s method to set the target (if implemented in its script).
	# This assumes your enemy boat script has a method like `set_target(target_node: Node3D)`.
	enemy_boat.call("set_target", player_boat)

# Timer signal callback to spawn enemy boats periodically.
func _on_Timer_timeout() -> void:
	spawn_enemy_boat()
