extends "res://BaseRifleGun.gd"

# Animation reference
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	# Set SCAR-L specific properties
	gun_type = "scarl"
	fire_rate = 0.12  # Slightly faster than M16A1
	bullet_damage = 3
	magazine_size = 30
	reload_time = 2.3
	accuracy = 0.92  # Better accuracy than M16A1
	recoil = 0.18    # Slightly less recoil
	automatic = true
	
	# Call parent _ready after setting properties
	super._ready()
	
	print_verbose("SCAR-L rifle initialized")

# Override shoot method to add recoil animation
func shoot() -> void:
	# Play recoil animation
	if animation_player != null and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")
	
	# Call the parent shoot method
	super.shoot()
