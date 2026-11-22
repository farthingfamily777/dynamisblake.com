extends Object
## Merge static town geometry into a few big meshes: one per (material look,
## 24 m cell). Cuts hundreds of draw calls to a few dozen while keeping
## frustum culling per cell. Animated, skinned, and character meshes are skipped.

const CELL := 40.0


static func _sig(m: Material) -> String:
	if not (m is StandardMaterial3D):
		return "id%d" % m.get_instance_id()
	var s := m as StandardMaterial3D
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [s.albedo_color, s.albedo_texture.get_rid().get_id() if s.albedo_texture else 0,
		s.uv1_scale, s.uv1_offset, s.uv1_triplanar, s.uv1_world_triplanar, s.transparency, s.emission_enabled, s.emission,
		s.shading_mode, s.vertex_color_use_as_albedo, s.cull_mode]


static func merge(root: Node3D, skip: Array) -> Dictionary:
	var skipset := {}
	for n in skip:
		if n is Node:
			skipset[n.get_instance_id()] = true
	var groups := {}
	var mats := {}
	var count := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if not _ok(mi, root, skipset):
			continue
		var mesh: Mesh = mi.mesh
		var xf: Transform3D = root.global_transform.affine_inverse() * mi.global_transform
		for si in mesh.get_surface_count():
			var mat: Material = mi.material_override if mi.material_override else mesh.surface_get_material(si)
			if mat == null:
				continue
			var p := xf.origin
			var key := "%s#%d,%d" % [_sig(mat), int(floor(p.x / CELL)), int(floor(p.z / CELL))]
			if not groups.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[key] = st
				mats[key] = mat
			(groups[key] as SurfaceTool).append_from(mesh, si, xf)
		mi.mesh = null
		count += 1
	var holder := Node3D.new()
	holder.name = "StaticMerged"
	root.add_child(holder)
	for k in groups:
		var out := MeshInstance3D.new()
		out.mesh = (groups[k] as SurfaceTool).commit()
		out.material_override = mats[k]
		holder.add_child(out)
	return {"merged": count, "meshes": groups.size()}


static func _ok(mi: MeshInstance3D, root: Node3D, skipset: Dictionary) -> bool:
	if mi.mesh == null or not mi.visible:
		return false
	if mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).get_blend_shape_count() > 0:
		return false
	if mi.get_node_or_null(mi.skeleton) is Skeleton3D:
		return false
	if mi.mesh.get_surface_count() == 0:
		return false
	if mi.material_override is ShaderMaterial:
		return false
	var n: Node = mi
	while n != null and n != root:
		if skipset.has(n.get_instance_id()) or n is CharacterBody3D or n is Skeleton3D or n.is_in_group("tag_target") or n.is_in_group("lp_body"):
			return false
		if n.name in ["Magic", "Overworld", "Buddy", "Villages", "Banker"]:
			return false
		n = n.get_parent()
	return true
