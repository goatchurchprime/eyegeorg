extends Node3D


@onready var skel : Skeleton3D = $readyplayerme_avatar/Armature/Skeleton3D
@onready var lefteyebone = skel.find_bone("LeftEye")
@onready var righteyebone = skel.find_bone("RightEye")
@onready var eyelookdownleftblendshape = $readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.find_blend_shape_by_name("eyeLookDownLeft")
@onready var eyelookdownrightblendshape = $readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.find_blend_shape_by_name("eyeLookDownRight")

func _ready():
	pass
	

func seteyeattorch(eyebone):
	var h = skel.global_transform*skel.get_bone_global_pose(eyebone)
	var ztobealigned = $Torch.global_transform.origin - h.origin
	var zcurrent = h.basis.z
	var crossprod = zcurrent.cross(ztobealigned)
	if crossprod.length() > 0.0001:
		var rot = Quaternion(crossprod.normalized(), asin(crossprod.length()))
		var rotorg = skel.get_bone_pose_rotation(eyebone)
		var rotnew = rotorg*rot
		skel.set_bone_pose_rotation(eyebone, rotnew)
	h.origin += h.basis.z*0.04

func _process(delta):
	seteyeattorch(lefteyebone)
	seteyeattorch(righteyebone)
	var h = skel.global_transform*skel.get_bone_global_pose(lefteyebone)
	h.origin += h.basis.z*0.04
	$EyeMarker2.transform = h
	var lefteyevec = Basis(skel.get_bone_pose_rotation(lefteyebone)).z
	var lefteyedownness = -0.12 - lefteyevec.y
	$readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.set_blend_shape_value(eyelookdownleftblendshape, max(0.0, lefteyedownness)*5.0)
	var ll = clamp(Vector2(lefteyevec.x, lefteyevec.y).length(), 0, 0.2)
	var pupilradl = lerp(0.05, 0.10, ll*5)
	$readyplayerme_avatar/Armature/Skeleton3D/EyeLeft.get_surface_override_material(0).set_shader_parameter("pupilrad", pupilradl)

	var righteyevec = Basis(skel.get_bone_pose_rotation(righteyebone)).z
	var righteyedownness = -0.12 - righteyevec.y
	$readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.set_blend_shape_value(eyelookdownrightblendshape, max(0.0, righteyedownness)*5.0)
	var rl = clamp(Vector2(righteyevec.x, righteyevec.y).length(), 0, 0.2)
	var pupilradr = lerp(0.05, 0.10, rl*5)
	$readyplayerme_avatar/Armature/Skeleton3D/EyeRight.get_surface_override_material(0).set_shader_parameter("pupilrad", pupilradr)

	#print(Basis(skel.get_bone_pose_rotation(lefteyebone)).z.y)

func _on_h_slider_value_changed(value):
	$readyplayerme_avatar.rotation_degrees.y = (value - 50)/100.0 * 90


func _on_h_slider_light_value_changed(value):
	$Torch.position.x = (value - 50)/100.0 * 0.2;

func _on_v_slider_value_changed(value):
	$Torch.position.y = (value - 50)/100.0 * 0.2;
