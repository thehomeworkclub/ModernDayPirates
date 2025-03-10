extends Node3D

# A simple marker that defines where enemy ships will stop
# You can move this object in the editor or at runtime to adjust where ships stop

@export var move_speed: float = 5.0  # Speed when moving with keys

func _ready():
	print("Enemy barrier initialized at Z position: ", global_position.z)
	print("TIP: Use '[' and ']' keys to move the barrier closer or further")
	
	# Make sure it's visible in front of other elements
	if has_node("BarrierVisual"):
		$BarrierVisual.visible = true

func _process(delta):
	# Allow moving the barrier with keyboard
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		# Move barrier away from player (more negative Z)
		global_position.z -= move_speed * delta
		print("Barrier moved to Z: ", global_position.z)
	
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		# Move barrier toward player (less negative Z)
		global_position.z += move_speed * delta
		print("Barrier moved to Z: ", global_position.z)