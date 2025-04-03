extends CharacterBody3D

var SPEED = 5.0
const JUMP_VELOCITY = 4.5
var hp = 100
var hitimmunity = 20

func _ready():
    PlayerVariables.player = self
    add_to_group("player")

func damage(damage):
    hp -= damage

func _physics_process(delta):
    PlayerVariables.player = self
    
    # Handle jump.
    if Input.is_action_just_pressed("ui_accept"):
        velocity.y = JUMP_VELOCITY
    if Input.is_action_just_pressed("shift"):
        velocity.y = -JUMP_VELOCITY

    # Get the input direction and handle the movement/deceleration.
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
        var collision = get_slide_collision(index)
        
        if collision.get_collider() == null:
            continue
            
        if collision.get_collider() is Enemy:
            var mob = collision.get_collider()
            hitimmunity = 40
            mob.take_damage(10)
            break
