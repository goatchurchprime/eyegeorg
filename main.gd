extends Node3D


@onready var skel : Skeleton3D = $readyplayerme_avatar/Armature/Skeleton3D
@onready var lefteyebone = skel.find_bone("LeftEye")
@onready var righteyebone = skel.find_bone("RightEye")
@onready var eyelookdownleftblendshape = $readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.find_blend_shape_by_name("eyeLookDownLeft")
@onready var eyelookdownrightblendshape = $readyplayerme_avatar/Armature/Skeleton3D/Wolf3D_Head.find_blend_shape_by_name("eyeLookDownRight")

func _ready():
	_on_reset_light_pressed()

var angspeedpersec = deg_to_rad(80)
var pupilradspeedpersec = 0.06

func seteyeattorch(eyebone, deviantquat, restriction, delta):
	var h = skel.global_transform*skel.get_bone_global_pose(eyebone)
	var ztobealigned = $Torch.global_transform.origin - h.origin
	ztobealigned = ztobealigned.normalized()
	ztobealigned = deviantquat*ztobealigned
	var mideyeaxis = $readyplayerme_avatar.basis.z
	var eyedevcross = mideyeaxis.cross(ztobealigned)
	var eyedevang = asin(eyedevcross.length())
	if eyedevang > restriction:
		ztobealigned = Quaternion(eyedevcross.normalized(), restriction)*mideyeaxis
	
	var zcurrent = h.basis.z
	var crossprod = zcurrent.cross(ztobealigned)
	if crossprod.length() > 0.0001:
		var ang = asin(crossprod.length())
		ang = min(ang, delta*angspeedpersec)
		var rot = Quaternion(crossprod.normalized(), ang)
		var rotorg = skel.get_bone_pose_rotation(eyebone)
		var rotnew = rotorg*rot
		skel.set_bone_pose_rotation(eyebone, rotnew)
		#if eyebone == lefteyebone:
		#	print("z", Basis(rotnew).z)
	#h.origin += h.basis.z*0.04

var lefteyedeviant = Quaternion()
var righteyedeviant = Quaternion()
var lefteyerestriction = deg_to_rad(25)
var righteyerestriction = deg_to_rad(25)
func _process(delta):
	seteyeattorch(lefteyebone, lefteyedeviant, lefteyerestriction, delta)
	seteyeattorch(righteyebone, righteyedeviant, righteyerestriction, delta)
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
	var orgpupilrad = $readyplayerme_avatar/Armature/Skeleton3D/EyeLeft.get_surface_override_material(0).get_shader_parameter("pupilrad")
	var pupilradspeedperframe = pupilradspeedpersec*delta
	if abs(puplilrad - orgpupilrad) > pupilradspeedperframe:
		puplilrad = orgpupilrad + (pupilradspeedperframe if puplilrad > orgpupilrad else -pupilradspeedperframe)
	$readyplayerme_avatar/Armature/Skeleton3D/EyeLeft.get_surface_override_material(0).set_shader_parameter("pupilrad", puplilrad)
	$readyplayerme_avatar/Armature/Skeleton3D/EyeRight.get_surface_override_material(0).set_shader_parameter("pupilrad", puplilrad)

func _on_h_slider_value_changed(value):
	$readyplayerme_avatar.rotation_degrees.y = (value - 50)/100.0 * 90

var torchdragoffset = Vector2(0,0)
var torchz = 0
var dragitem = null
func _on_reset_light_pressed():
	torchz = $Torch.position.z
	torchdragoffset = Vector2(0,0)
	dragitem = $Torch
	dragtorch(Vector2(458, 917))
	dragitem = null

func downclick(eposition):
	$RayCast3D.position = $Camera3D.project_ray_origin(eposition)
	$RayCast3D.target_position = $Camera3D.project_position(eposition, 3.0) - $RayCast3D.position
	$RayCast3D.force_raycast_update()
	dragitem = $RayCast3D.get_collider()
	if dragitem != null:
		torchdragoffset = $Camera3D.unproject_position(dragitem.position) - eposition
		torchz = dragitem.position.z
		var dN = $Camera3D.project_ray_normal(torchdragoffset + eposition)
		var dO = $Camera3D.project_ray_origin(torchdragoffset + eposition)
		var dL = (torchz - dO.z)/dN.z
		dragitem.get_node("CollisionShape3D/DragHighlight").visible = true
		
var torchfocusdist = 0.4
var torchfocusup = 0.04
func dragtorch(eposition):
	var dN = $Camera3D.project_ray_normal(torchdragoffset + eposition)
	var dO = $Camera3D.project_ray_origin(torchdragoffset + eposition)
	var dL = (torchz - dO.z)/dN.z
	var torchfocus = $Camera3D.position - torchfocusdist*$Camera3D.basis.z + torchfocusup*$Camera3D.basis.y
	if dragitem == $Torch:
		dragitem.look_at_from_position(dO + dN*dL, torchfocus)
	else:
		dragitem.position = dO + dN*dL
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				downclick(event.position)
			elif dragitem != null:
				dragitem.get_node("CollisionShape3D/DragHighlight").visible = false
				dragitem = null
				
	elif event is InputEventMouseMotion:
		if dragitem != null:
			dragtorch(event.position)

func _on_condition_item_selected(index):
	var c = $Condition.get_item_text(index).split(" ")
	lefteyedeviant = Quaternion()
	righteyedeviant = Quaternion()
	if "Deviant" in c:
		if "Left" in c:
			lefteyedeviant = Quaternion(Vector3(0,1,0), deg_to_rad(20))
		else:
			righteyedeviant = Quaternion(Vector3(0,1,0), deg_to_rad(20))

	lefteyerestriction = deg_to_rad(25)
	righteyerestriction = deg_to_rad(25)
	if "Restricted" in c:
		if "Left" in c:
			lefteyerestriction = deg_to_rad(10)
		else:
			righteyerestriction = deg_to_rad(10)
