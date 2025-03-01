extends Area3D

@export var base_health: int = 3
@export var base_speed: float = 2.0
@export var base_bronze_value: int = 2

var health: int
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0
var bronze_value: int = 0

func _ready() -> void:
	# Set up group membership
	add_to_group("Enemy")
	
	# Basic collision setup - keep it simple
	collision_layer = 4  # Enemy layer
	collision_mask = 2   # Bullet layer
	
	# Ensure collision detection is enabled
	monitoring = true
	monitorable = true
	
	# Calculate health based on difficulty
	var round_bonus = GameManager.current_round - 1
	health = int(base_health * health_multiplier) + round_bonus
	
	# Calculate bronze value based on health and round
	var difficulty_factor = 1.0
	match GameManager.difficulty:
		"Easy": difficulty_factor = 1.0
		"Normal": difficulty_factor = 1.2
		"Hard": difficulty_factor = 1.5
		"Very Hard": difficulty_factor = 1.8
		"Extreme": difficulty_factor = 2.0
	
	bronze_value = int(base_bronze_value * difficulty_factor + GameManager.current_round)
	
	# Connect signal using the new signal syntax
	area_entered.connect(_on_area_entered)
	
	# Make sure the boat is visible
	if has_node("ScoutBoat"):
		$ScoutBoat.visible = true
	
	# Print collision setup for debugging
	print("DEBUG: Enemy ready with health: ", health, " at position: ", global_position)
	print("DEBUG: Enemy collision layer: ", collision_layer, ", mask: ", collision_mask)

func _physics_process(delta: float) -> void:
	# Apply speed multiplier from difficulty
	var adjusted_speed = base_speed * speed_multiplier
	
	# Move the enemy toward the player (who is at negative Z)
	# This is the standard movement logic
	global_translate(Vector3(0, 0, -adjusted_speed * delta))
	
	# Ensure Y position stays at ground level
	if global_position.y != 0:
		global_position.y = 0
	
	# Add some debug visualization - remove in production
	if Engine.get_physics_frames() % 120 == 0:  # Less frequent debug output
		print("DEBUG: Enemy at position: ", global_position, " moving with speed: ", adjusted_speed)

func _on_area_entered(area: Area3D) -> void:
	print("DEBUG: Enemy collision with ", area.name)
	
	# Simple group-based check
	if area.is_in_group("Bullet"):
		print("DEBUG: Enemy hit by bullet")
		var damage = area.get_damage() if area.has_method("get_damage") else 1
		take_damage(damage)

func take_damage(damage: int) -> void:
	print("DEBUG: Enemy taking damage: ", damage)
	health -= damage
	
	# Flash or visual indicator could be added here
	
	if health <= 0:
		print("DEBUG: Enemy defeated!")
		
		# Award bronze for defeating enemy
		CurrencyManager.add_bronze(bronze_value)
		
		# Notify GameManager that an enemy has been defeated
		GameManager.enemy_defeated()
		
		# Destroy the enemy
		queue_free()
