extends Node3D


@onready var skel : Skeleton3D = $readyplayerme_avatar/Armature/Skeleton3D
@onready var lefteyebone = skel.find_bone("LeftEye")
@onready var righteyebone = skel.find_bone("RightEye")
@onready var eyelookdownleftblendshape = $readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.find_blend_shape_by_name("eyeLookDownLeft")
@onready var eyelookdownrightblendshape = $readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.find_blend_shape_by_name("eyeLookDownRight")

func _ready():
	_on_reset_light_pressed()

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
	var pupilradl = lerp(0.06, 0.10, ll*5)

	var righteyevec = Basis(skel.get_bone_pose_rotation(righteyebone)).z
	var righteyedownness = -0.12 - righteyevec.y
	$readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.set_blend_shape_value(eyelookdownrightblendshape, max(0.0, righteyedownness)*5.0)
	var rl = clamp(Vector2(righteyevec.x, righteyevec.y).length(), 0, 0.2)
	var pupilradr = lerp(0.06, 0.10, rl*5)

	var puplilrad = min(pupilradl, pupilradr)
	$readyplayerme_avatar/Armature/Skeleton3D/EyeLeft.get_surface_override_material(0).set_shader_parameter("pupilrad", puplilrad)
	$readyplayerme_avatar/Armature/Skeleton3D/EyeRight.get_surface_override_material(0).set_shader_parameter("pupilrad", puplilrad)

	#print(Basis(skel.get_bone_pose_rotation(lefteyebone)).z.y)

func _on_h_slider_value_changed(value):
	$readyplayerme_avatar.rotation_degrees.y = (value - 50)/100.0 * 90

var torchdragoffset = Vector2(0,0)
var torchz = 0
func _on_reset_light_pressed():
	torchz = $Torch.position.z
	torchdragoffset = Vector2(0,0)
	dragtorch(Vector2(458, 917))

func downclick(eposition):
	$RayCast3D.position = $Camera3D.project_ray_origin(eposition)
	$RayCast3D.target_position = $Camera3D.project_position(eposition, 3.0) - $RayCast3D.position
	$RayCast3D.force_raycast_update()
	if $RayCast3D.get_collider() == $Torch:
		torchdragoffset = $Camera3D.unproject_position($Torch.position) - eposition
		torchz = $Torch.position.z
		var dN = $Camera3D.project_ray_normal(torchdragoffset + eposition)
		var dO = $Camera3D.project_ray_origin(torchdragoffset + eposition)
		var dL = (torchz - dO.z)/dN.z
		$Torch/CollisionShape3D/DragHighlight.visible = true
		
var torchfocusdist = 0.4
var torchfocusup = 0.04
func dragtorch(eposition):
	var dN = $Camera3D.project_ray_normal(torchdragoffset + eposition)
	var dO = $Camera3D.project_ray_origin(torchdragoffset + eposition)
	var dL = (torchz - dO.z)/dN.z
	var torchfocus = $Camera3D.position - torchfocusdist*$Camera3D.basis.z + torchfocusup*$Camera3D.basis.y
	$Torch.look_at_from_position(dO + dN*dL, torchfocus)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				downclick(event.position)
			elif torchdragoffset != null:
				$Torch/CollisionShape3D/DragHighlight.visible = false
				
	elif event is InputEventMouseMotion:
		if $Torch/CollisionShape3D/DragHighlight.visible:
			dragtorch(event.position)
