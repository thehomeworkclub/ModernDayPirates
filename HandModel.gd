extends Node3D

# This script is attached to hand models to manage their display and animations

@export var is_left_hand: bool = false

# References to finger joints for easy animation
var thumb_joints = []
var index_joints = []
var middle_joints = []
var ring_joints = []
var pinky_joints = []

func _ready():
	# Find all joints if using a skeleton
	var skeleton = find_child("Skeleton3D", true)
	
	if skeleton:
		# Find joints by name pattern - adjust this based on your model
		for i in range(skeleton.get_bone_count()):
			var bone_name = skeleton.get_bone_name(i).to_lower()
			
			if "thumb" in bone_name:
				thumb_joints.append(i)
			elif "index" in bone_name:
				index_joints.append(i)
			elif "middle" in bone_name:
				middle_joints.append(i)
			elif "ring" in bone_name:
				ring_joints.append(i)
			elif "pinky" in bone_name or "little" in bone_name:
				pinky_joints.append(i)
	
	# Adjust visual properties based on hand type
	if is_left_hand:
		# If this is a symmetrical mesh that needs to be flipped
		scale.x = -1.0  # Mirror the hand

# If you don't have animations, you can programmatically pose the hand
func set_point_pose(amount: float):
	var skeleton = find_child("Skeleton3D", true)
	if not skeleton or index_joints.empty():
		return
		
	# Bend index finger based on amount (0.0 - 1.0)
	for joint in index_joints:
		# Apply rotation to bend finger - adjust axis based on your model
		var current_rot = skeleton.get_bone_pose_rotation(joint)
		var target_rot = Quaternion(Vector3(1, 0, 0), deg_to_rad(20.0 * amount))
		skeleton.set_bone_pose_rotation(joint, current_rot * target_rot)

func set_grip_pose(amount: float):
	var skeleton = find_child("Skeleton3D", true)
	if not skeleton:
		return
		
	# Bend all fingers except thumb
	var finger_arrays = [index_joints, middle_joints, ring_joints, pinky_joints]
	
	for finger in finger_arrays:
		for joint in finger:
			# Apply rotation to curl finger
			var current_rot = skeleton.get_bone_pose_rotation(joint)
			var target_rot = Quaternion(Vector3(1, 0, 0), deg_to_rad(30.0 * amount))
			skeleton.set_bone_pose_rotation(joint, current_rot * target_rot)
	
	# Adjust thumb separately
	for joint in thumb_joints:
		var current_rot = skeleton.get_bone_pose_rotation(joint)
		var target_rot = Quaternion(Vector3(0, 0, 1), deg_to_rad(15.0 * amount))
		skeleton.set_bone_pose_rotation(joint, current_rot * target_rot)
