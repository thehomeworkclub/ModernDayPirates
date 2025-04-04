extends Node

# Base game parameters - all of these can be scaled with difficulty
var ships_per_batch: int = 2      # Base number of ships per spawn batch
var total_ships_per_wave: int = 10 # Total ships to spawn per wave
var bomb_damage: int = 2          # Base damage bombs deal to player
var bullet_damage: int = 1        # Base damage bullets deal to player
var bullet_cooldown: float = 5.0  # Base time between bullet shots (seconds)
var bomb_cooldown: float = 10.0   # Base time between bomb shots (seconds)
var max_bombers: int = 1          # Max number of ships that can shoot bombs at once

# Difficulty scaling values
var difficulty_level: int = 1     # Current difficulty level
var health_scale: float = 1.0     # Health scaling with difficulty
var damage_scale: float = 1.0     # Damage scaling with difficulty
var speed_scale: float = 1.0      # Speed scaling with difficulty
var spawn_scale: float = 1.0      # Spawn rate scaling with difficulty

# Wave properties
var ships_per_wave_per_difficulty: int = 2  # Additional ships per wave per difficulty level

func _init() -> void:
	print("GameParameters initialized")
	# Set initial parameters
	set_difficulty(1)

# Set the current difficulty level and update all scaled parameters
func set_difficulty(level: int) -> void:
	difficulty_level = max(1, level)  # Ensure minimum difficulty of 1
	print("Setting difficulty level to: ", difficulty_level)
	
	# Scale parameters based on difficulty
	health_scale = 1.0 + (difficulty_level - 1) * 0.25  # +25% health per level
	damage_scale = 1.0 + (difficulty_level - 1) * 0.2   # +20% damage per level
	speed_scale = 1.0 + (difficulty_level - 1) * 0.15   # +15% speed per level
	spawn_scale = 1.0 + (difficulty_level - 1) * 0.1    # +10% spawn rate per level
	
	print("Difficulty scaling factors:")
	print("- Health scale: ", health_scale)
	print("- Damage scale: ", damage_scale)
	print("- Speed scale: ", speed_scale)
	print("- Spawn scale: ", spawn_scale)

# Get current ships per batch (scaled by difficulty)
func get_ships_per_batch() -> int:
	return ships_per_batch
	
# Get total ships per wave (scaled by difficulty)
func get_total_ships_per_wave() -> int:
	return total_ships_per_wave + (difficulty_level - 1) * ships_per_wave_per_difficulty
	
# Get current bomb damage (scaled by difficulty)
func get_bomb_damage() -> int:
	return int(bomb_damage * damage_scale)
	
# Get current bullet damage (scaled by difficulty)
func get_bullet_damage() -> int:
	return int(bullet_damage * damage_scale)
	
# Get current bullet cooldown (reduced by difficulty)
func get_bullet_cooldown() -> float:
	# Reduce cooldown as difficulty increases (but never below 1.0 second)
	return max(1.0, bullet_cooldown / spawn_scale)
	
# Get current bomb cooldown (reduced by difficulty)
func get_bomb_cooldown() -> float:
	# Reduce cooldown as difficulty increases (but never below 3.0 seconds)
	return max(3.0, bomb_cooldown / spawn_scale)
