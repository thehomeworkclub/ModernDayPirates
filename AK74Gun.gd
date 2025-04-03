extends "res://BaseRifleGun.gd"

# Animation reference
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	# Set AK-74 specific properties
	gun_type = "ak74"
	fire_rate = 0.1  # Slightly faster than M16A1
	bullet_damage = 3  # Higher damage
	magazine_size = 30
	reload_time = 3.0  # Slightly longer reload
	accuracy = 0.85  # Slightly less accurate
	recoil = 0.25    # More recoil
	automatic = true
	
	# Call parent _ready after setting properties
	super._ready()
	
	print_verbose("AK-74 rifle initialized")

# Override shoot method to add recoil animation
func shoot() -> void:
	# Play recoil animation
	if animation_player != null and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")
	
	# Call the parent shoot method
	super.shoot()
