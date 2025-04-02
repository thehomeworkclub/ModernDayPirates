class_name Enemy
extends CharacterBody3D

# Base enemy properties
@export var max_health: int = 100.0
@export var movement_speed: float = 5.0
@export var base_damage: int = 10

# Common variables
var health: float
var is_dead: bool = false

# Signals
signal enemy_died(enemy)

func _ready():
	# Initialize health
	health = max_health
	
	# Add to enemy group
	add_to_group("enemy")
	
	
	# Call custom initialization
	_init_enemy()
	

# Virtual method for child classes to override
func _init_enemy():
	pass

func _physics_process(delta):
	if is_dead:
		return
		
	# Base movement logic
	_handle_movement(delta)

# Virtual method for movement logic
func _handle_movement(delta):
	pass

func take_damage(amount):
	health -= amount
	print(health)
	
	if health <= 0:
		die()

func die():
	is_dead = true
	emit_signal("enemy_died", self)
	queue_free()

func get_max_health():
	return max_health

func set_max_health(new_health):
	max_health = new_health
	health = new_health
