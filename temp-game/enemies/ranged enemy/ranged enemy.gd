extends Enemy
class_name RangedEnemy

@export var speed: float = 5.0
@export var accel: float = 10.0
@export var stop_distance: float = 3.0  # Distance before reaching the player

@onready var nav: NavigationAgent3D = $NavigationAgent3D  # Ensure you have a NavigationAgent3D
@onready var laser = preload("res://enemies/ranged enemy/laser.tscn")
@onready var animation = $AnimationPlayer
var target_position: Vector3
var reached_target: bool = false  # Flag to stop movement when reaching the point
var attack_cd = 200


func fire_laser():
	if PlayerVariables.player && !is_dead:  # Ensure player exists
		var laster_instance = laser.instantiate()  # Create the laser instance
		get_parent().add_child(laster_instance)  # Add to scene
		laster_instance.set_laser_positions(global_position, PlayerVariables.player.global_position)
		animation.play("attack")
func die():
	is_dead = true
	animation.animation_finished.connect(handle_anim_die)
	animation.clear_queue()
	animation.stop()
	animation.play("die")
	
func handle_anim_die(anim_name):
	if anim_name == "die":
		is_dead = true
		enemy_died.emit()
		queue_free()
func _physics_process(delta): 
	var can_atk = (attack_cd == 0)
	if !can_atk:
		attack_cd -= 1
		return
	var player_pos = PlayerVariables.player.global_position
	target_position = global_position.lerp(player_pos, .5)
	fire_laser()
	PlayerVariables.player.SPEED -= 1
	PlayerVariables.player.damage(base_damage)
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = .5
	timer.one_shot = true
	timer.timeout.connect(func(): PlayerVariables.player.SPEED +=1)
	timer.start()
		
	attack_cd = 200
