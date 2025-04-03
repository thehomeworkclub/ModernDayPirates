extends "res://BaseRifleGun.gd"

# Animation reference
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	# Set HK416 specific properties
	gun_type = "hk416"
	fire_rate = 0.14
	bullet_damage = 3
	magazine_size = 30
	reload_time = 2.4
	accuracy = 0.95  # High accuracy, as this is a precision rifle
	recoil = 0.15    # Low recoil for better precision
	automatic = true
	
	# Call parent _ready after setting properties
	super._ready()
	
	print_verbose("HK416 rifle initialized")

# Override shoot method to add recoil animation
func shoot() -> void:
	# Play recoil animation
	if animation_player != null and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")
	
	# Call the parent shoot method
	super.shoot()
