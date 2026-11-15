extends Node3D
# A low-poly person's root. Game code rotates plain pivot nodes (Hips, Head,
# ArmL/ForeL, ArmR/ForeR, LegL/ShinL, LegR/ShinR); each frame this copies those
# pivots onto the Skeleton3D bones so the single merged, skinned mesh follows.

var pivots: Array = []
var skel: Skeleton3D


func _process(_delta: float) -> void:
	if skel == null:
		return
	for i in pivots.size():
		var n: Node3D = pivots[i]
		skel.set_bone_pose_position(i, n.position)
		skel.set_bone_pose_rotation(i, n.quaternion)
