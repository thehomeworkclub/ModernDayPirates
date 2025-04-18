# MeleeEnemy.gd
extends Enemy
class_name MeleeEnemy
# Melee-specific properties
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

# Melee components
@onready var attack_timer: Timer = $AttackTimer
@onready var nav = $NavigationAgent3D
@onready var animation = $AnimationPlayer

var speed = 5
var accel = 6
func _init_enemy():
	# Initialize melee-specific components
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true

func _handle_movement(delta):
	var direction = Vector3()
	nav.target_position = PlayerVariables.player.global_position
	direction = (nav.get_next_path_position()*1.03) - global_position
	direction = direction.normalized()
	velocity = velocity.lerp(direction * speed, accel * delta)
	move_and_slide()
	var player = PlayerVariables.player
	if global_position.distance_to(player.global_position) < 1.5 && !is_dead:
		_attack()
		player.damage(base_damage)
		
func _attack():
	animation.play("attack")

func _ready():
	print("MeleeEnemy READY! Name: ", self.name, " | Type: ", self.get_class())
	super() # Calls Enemy's _ready()

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
	look_at(Vector3(PlayerVariables.player.global_position.x, global_position.y, PlayerVariables.player.global_position.z), Vector3.UP)
	_handle_movement(delta)
