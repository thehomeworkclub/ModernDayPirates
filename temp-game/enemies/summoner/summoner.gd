# MeleeEnemy.gd
extends Enemy
class_name SummonerEnemy
# Melee-specific properties
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

# Melee components
@onready var attack_timer: Timer = $AttackTimer
@onready var nav = $NavigationAgent3D

@onready var minion = preload("res://enemies/summoner/minion/minion.tscn")

var speed = 5
var accel = 6
func _init_enemy():
	# Initialize melee-specific components
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true

func _handle_movement(delta):
	var direction = Vector3()
	nav.target_position = PlayerVariables.player.global_position
	direction = nav.get_next_path_position() - global_position
	direction = direction.normalized()
	velocity = velocity.lerp(direction * speed, accel * delta)
	move_and_slide()

func _summon():
	pass

#func _perform_melee_attack():
	## Start cooldown
	#attack_timer.start()
	#
	## Play attack animation
	## $AnimationPlayer.play("attack")
	#
	## Check for player in attack area
	#for body in bodies:
		#if body.is_in_group("player") and body.has_method("take_damage"):
			#body.take_damage(base_damage)
			#print("Melee hit on player!")
			
func _physics_process(delta):
	_handle_movement(delta)
