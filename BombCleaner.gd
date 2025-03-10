extends Node

# This script used to clean up stuck bombs, but now just provides monitoring
# All bomb removal code has been commented out to ensure bombs reach the player

var check_interval: float = 10.0  # Reduced frequency to avoid console spam
var time_since_last_check: float = 0.0

func _ready() -> void:
	print("BombCleaner: Initialized (MONITORING ONLY - NO REMOVAL)")
	
	# Just print bomb count on startup
	var bombs = get_tree().get_nodes_in_group("EnemyBomb")
	print("DEBUG: Found ", bombs.size(), " active bombs at startup")

func _process(delta: float) -> void:
	time_since_last_check += delta
	
	if time_since_last_check >= check_interval:
		time_since_last_check = 0.0
		count_bombs()

# Just count bombs - no removal
func count_bombs() -> void:
	var bombs = get_tree().get_nodes_in_group("EnemyBomb")
	print("DEBUG: Currently ", bombs.size(), " active bombs in scene")
	
	# Log positions of active bombs
	if bombs.size() > 0:
		print("DEBUG: Active bomb positions:")
		for i in range(min(bombs.size(), 5)):  # Log up to 5 bombs
			if bombs[i] and is_instance_valid(bombs[i]):
				print("  Bomb ", i, ": ", bombs[i].global_position)

# COMMENTED OUT: All bomb removal functionality
#func _clean_stuck_bombs() -> void:
#	var bombs = get_tree().get_nodes_in_group("EnemyBomb")
#	var cleanup_count = 0
#	
#	for bomb in bombs:
#		var should_remove = false
#		
#		# Check if the bomb has been properly initialized
#		if bomb.has_method("is_initialized"):
#			if not bomb.is_initialized():
#				should_remove = true
#				print("DEBUG: Removing uninitialized bomb")
#		
#		# Check if the bomb is not moving (stuck)
#		if not should_remove and bomb.has_method("get_velocity"):
#			var velocity = bomb.get_velocity()
#			if velocity.length() < 0.1:  # Almost no movement
#				should_remove = true
#				print("DEBUG: Removing stationary bomb")
#		
#		# Check if the bomb is at Y=0 (likely on the ground)
#		if not should_remove and bomb.global_position.y < 0.1:
#			should_remove = true
#			print("DEBUG: Removing ground-level bomb")
#			
#		# Check if the bomb has an owner and the owner doesn't exist anymore
#		if not should_remove and bomb.has_method("get_owner_id"):
#			var owner_id = bomb.get_owner_id()
#			if owner_id != -1:
#				# Check if the owner enemy still exists
#				var owner_found = false
#				var enemies = get_tree().get_nodes_in_group("Enemy")
#				for enemy in enemies:
#					if enemy.get("enemy_id") == owner_id:
#						owner_found = true
#						break
#						
#				if not owner_found:
#					# If owner doesn't exist, remove the bomb
#					should_remove = true
#					print("DEBUG: Removing bomb with non-existent owner")
#		
#		# Remove the bomb if any conditions were met
#		if should_remove:
#			bomb.queue_free()
#			cleanup_count += 1
#	
#	if cleanup_count > 0:
#		print("BombCleaner: Removed ", cleanup_count, " stuck bombs")
