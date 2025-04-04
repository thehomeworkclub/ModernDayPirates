# MeleeEnemy.gd
extends Enemy
class_name SummonerEnemy
# Melee-specific properties
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 10.0

# Melee components
@onready var attack_timer: Timer = $AttackTimer
@onready var nav = $NavigationAgent3D
@onready var pMin1 = $summon1.global_position
@onready var pMin2 = $summon2.global_position
@onready var pMin3 = $summon3.global_position
@onready var pMin4 = $summon4.global_position

@onready var minion = preload("res://enemies/summoner/minion/minion.tscn")

var speed = 5
var accel = 6
func _init_enemy():
	# Initialize melee-specific components
	attack_timer.wait_time = attack_cooldown

func _handle_movement(delta):
	var direction = Vector3()
	nav.target_position = PlayerVariables.player.global_position
	direction = nav.get_next_path_position() - global_position
	direction = direction.normalized()
	velocity = velocity.lerp(direction * speed, accel * delta)
	move_and_slide()
func spawn_minion(pos):
	minion.instantiate()
	minion.global_position = pos
	add_child(minion)

func _summon():
	spawn_minion(pMin1)
	spawn_minion(pMin2)
	spawn_minion(pMin3)
	spawn_minion(pMin4)

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
