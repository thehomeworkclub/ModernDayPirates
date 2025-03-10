extends Node

# This script detects when enemies are too close to the player's boat
# and helps enforce the barrier distance

@export var barrier_distance: float = 20.0
var player_boat = null
var enemies_at_barrier = []

func _ready():
	# Find the player boat
	var boats = get_tree().get_nodes_in_group("Player")
	if boats.size() > 0:
		player_boat = boats[0]
		print("DEBUG: Found player boat at ", player_boat.global_position)
	else:
		print("ERROR: Player boat not found!")

func _physics_process(delta):
	if !player_boat:
		return
		
	# Get all enemies
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	for enemy in enemies:
		# Calculate distance to player
		var distance = enemy.global_position.distance_to(player_boat.global_position)
		var z_distance = player_boat.global_position.z - enemy.global_position.z
		
		# If enemy is too close, push them back
		if distance < barrier_distance || z_distance > -5.0:
			# Make sure enemy stops
			enemy.at_barrier = true
			
			# If enemy not in barrier list, add them
			if !enemies_at_barrier.has(enemy):
				enemies_at_barrier.append(enemy)
				print("DEBUG: Enemy reached barrier, enforcing distance")
				
			# Damage the player at regular intervals (handled in the enemy script)
		else:
			# Remove from barrier list if they moved away
			if enemies_at_barrier.has(enemy):
				enemies_at_barrier.erase(enemy)