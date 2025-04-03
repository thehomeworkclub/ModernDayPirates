extends Area3D

@export var speed: float = 60.0  # Higher speed for better simulation
@export var damage: int = 1
@export var lifetime: float = 5.0  # Seconds before automatically destroying

var direction: Vector3 = Vector3.FORWARD
var start_pos: Vector3
var life_timer: Timer

func _ready() -> void:
	# Store the starting position for distance culling
	start_pos = global_position
	
	# Setup lifecycle timer
	life_timer = Timer.new()
	life_timer.wait_time = lifetime
	life_timer.one_shot = true
	life_timer.timeout.connect(_on_lifetime_timeout)
	add_child(life_timer)
	life_timer.start()
	
	# Connect area entered signal
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Add a small initial rotation for realism
	rotation = Vector3(
		randf_range(-0.05, 0.05),
		randf_range(-0.05, 0.05),
		0
	)
	
	# Debug info
	print_verbose("Bullet spawned with damage: " + str(damage))

func _physics_process(delta: float) -> void:
	# Move in direction
	global_position += direction * speed * delta
	
	# Apply slight gravity and deceleration for realism
	direction.y -= 0.01 * delta
	speed = max(speed - 5.0 * delta, 40.0)  # Slow down slightly over time, but keep minimum speed
	
	# Add slight spin for visual effect
	rotate_x(delta * 15.0)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print_verbose("Bullet hit: " + body.name)
	
	_impact_effect()
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		print_verbose("Bullet hit area: " + area.name)
	
	_impact_effect()
	queue_free()

func _impact_effect() -> void:
	# This would be where we play particle effects, sounds, etc.
	# For now just print debug info
	print_verbose("Bullet impact!")

func _on_lifetime_timeout() -> void:
	queue_free()
