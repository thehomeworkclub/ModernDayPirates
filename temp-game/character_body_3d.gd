extends CharacterBody3D


var SPEED = 5.0
const JUMP_VELOCITY = 4.5
var hp = 100
var hitimmunity = 20
var camera = $Camera3D
func _ready():
	PlayerVariables.player = self
	add_to_group("player")
	camera.set_current()
	
func damage(damage):
	hp -= damage
	
func _physics_process(delta):
	PlayerVariables.player = self
	# Add the gravity.

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("shift"):
		velocity.y = -JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	var can_be_hit = (hitimmunity == 0)
	if !can_be_hit:
		hitimmunity -= 1
		return
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)

		# If there are duplicate collisions with a mob in a single frame
		# the mob will be deleted after the first collision, and a second call to
		# get_collider will return null, leading to a null pointer when calling
		# collision.get_collider().is_in_group("mob").
		# This block of code prevents processing duplicate collisions.
		if collision.get_collider() == null:
			continue

		# If the collider is with a mob
		if collision.get_collider() is Enemy:
			
			var mob = collision.get_collider()
			if mob.is_dead:
				break
			hitimmunity = 40
			# we check that we are hitting it from above.
			mob.take_damage(50)
			
			break
				# If so, we squash it and bounce.
				
	
	
