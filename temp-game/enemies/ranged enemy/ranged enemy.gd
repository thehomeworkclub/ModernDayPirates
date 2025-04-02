extends CharacterBody3D

@export var speed: float = 5.0
@export var accel: float = 10.0
@export var stop_distance: float = 3.0  # Distance before reaching the player

@onready var nav: NavigationAgent3D = $NavigationAgent3D  # Ensure you have a NavigationAgent3D
@onready var laser = preload("res://enemies/ranged enemy/laser.tscn")
var target_position: Vector3
var reached_target: bool = false  # Flag to stop movement when reaching the point
var attack_cd = 200

var hp = 0
var damage = 0


func fire_laser():
	if PlayerVariables.player:  # Ensure player exists
		var laster_instance = laser.instantiate()  # Create the laser instance
		get_parent().add_child(laster_instance)  # Add to scene
		laster_instance.set_laser_positions(global_position, PlayerVariables.player.global_position)

func _physics_process(delta): 
	var can_atk = (attack_cd == 0)
	if !can_atk:
		attack_cd -= 1
		return
	var player_pos = PlayerVariables.player.global_position
	target_position = global_position.lerp(player_pos, .5)
	fire_laser()
	PlayerVariables.player.SPEED -= 1
	PlayerVariables.player.damage(damage)
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = .5
	timer.one_shot = true
	timer.timeout.connect(func(): PlayerVariables.player.SPEED +=1)
	timer.start()
		
	attack_cd = 200
