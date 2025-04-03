extends "res://BaseRifleGun.gd"

# Animation reference
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	# Set M16A1 specific properties
	gun_type = "m16a1"
	fire_rate = 0.15
	bullet_damage = 2
	magazine_size = 30
	reload_time = 2.5
	accuracy = 0.9
	recoil = 0.2
	automatic = true
	
	# Call parent _ready after setting properties
	super._ready()
	
	print_verbose("M16A1 rifle initialized")

# Override shoot method to add recoil animation
func shoot() -> void:
	# Play recoil animation
	if animation_player != null and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")
	
	# Call the parent shoot method
	super.shoot()
