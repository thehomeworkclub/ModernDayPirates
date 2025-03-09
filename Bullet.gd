extends Area3D

@export var speed: float = 40.0  # Increased speed to make aiming easier
@export var damage: int = 1  # Default damage
@export var lifetime: float = 5.0  # Seconds before despawning

var age: float = 0.0
var direction: Vector3 = Vector3.FORWARD  # Will be set by gun when spawned

# Use _ready to set up collision and signals
func _ready() -> void:
	# Make sure it's visible
	visible = true
	
	# Set the mesh to be bright for visibility
	if has_node("MeshInstance3D"):
		$MeshInstance3D.visible = true
	
	# Add to bullet group for easier detection
	add_to_group("Bullet")
	
	# Connect to the area_entered signal
	area_entered.connect(_on_area_entered)
	
	print("DEBUG: Bullet initialized at ", global_position, " with direction ", direction)
	print("DEBUG: Bullet collision layer: ", collision_layer, ", mask: ", collision_mask)

# Move forward along the direction vector
func _physics_process(delta: float) -> void:
	# Move using global_translate with the direction vector
	global_translate(direction * speed * delta)
	
	# Track lifetime
	age += delta
	if age >= lifetime:
		queue_free()
	
	# Debug print movement occasionally
	if Engine.get_physics_frames() % 30 == 0:
		print("DEBUG: Bullet at ", global_position)

func _on_area_entered(area: Area3D) -> void:
	print("DEBUG: Bullet collided with ", area.name, " in group? ", 
		area.is_in_group("Enemy"), "/", area.is_in_group("EnemyBomb"))
	
	# More detailed collision detection
	if area.is_in_group("Enemy"):
		if area.has_method("take_damage"):
			print("DEBUG: Hitting enemy with ", damage, " damage")
			area.take_damage(damage)
			queue_free()
		else:
			print("WARNING: Enemy doesn't have take_damage method")
	elif area.is_in_group("EnemyBomb"):
		# Handle collision with bomb
		print("DEBUG: Bullet hit bomb")
		if area.has_method("explode"):
			area.explode(false)  # Explode but don't damage player
		queue_free()
	elif area.get_parent() and area.get_parent().is_in_group("Enemy"):
		# In case it's a child of an enemy
		print("DEBUG: Hitting enemy parent with ", damage, " damage")
		area.get_parent().take_damage(damage)
		queue_free()
	else:
		print("DEBUG: Hit something that is not an enemy: ", area.name)

func get_damage() -> int:
	return damage
