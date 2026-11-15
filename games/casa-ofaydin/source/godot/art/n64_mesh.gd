extends Object
# Late-90s character mesh builder (N64 / PS1 era): tapered 4- to 8-sided
# cylinders and lofts with smooth (Gouraud) normals, low ellipsoids for heads,
# domes for hair, helmets and pauldrons, and flat "painted" quads for trim.
# Shapes are recorded by art/lowpoly_character.gd, then this script:
#   1. generates geometry per LOD (LOD1 uses fewer sides and rings),
#   2. drops shapes sealed inside a bigger shape and end caps buried in others,
#   3. keeps shapes in priority order until the triangle cap,
#   4. commits one rigid-skinned surface (one bone per vertex) per LOD.

const SQ2 := 1.41421356


static func lod_sides(sh: Dictionary, lod: int) -> int:
	var n := int(sh.get("sides", 6))
	if lod == 0 or sh["kind"] == "box":
		return n
	return maxi(4, n - 2)


static func rings_of(sh: Dictionary, lod: int) -> Array:
	# [{y, rx, rz, col}] in the shape's own frame (centre at 0).
	var out: Array = []
	var top: Color = sh["color"]
	var bot: Color = sh["bot"]
	if sh["kind"] == "loft":
		for r in sh["rings"]:
			out.append({"y": float(r[0]), "rx": float(r[1]), "rz": float(r[2]), "col": r[3]})
		if lod == 1 and out.size() > 3:
			var thin: Array = [out[0]]
			for i in range(2, out.size() - 1, 2):
				thin.append(out[i])
			thin.append(out[out.size() - 1])
			out = thin
		return out
	var s: Vector3 = sh["s"]
	var segs := int(sh.get("segs", 1))
	if lod == 1:
		segs = 1
	var bulge := float(sh.get("bulge", 0.0))
	var tt: Vector2 = sh["tt"]
	var tb: Vector2 = sh["tb"]
	for k in segs + 1:
		var f := float(k) / segs
		var b := 1.0 + bulge * sin(PI * f)
		out.append({"y": -s.y * 0.5 + s.y * f, "rx": s.x * 0.5 * lerpf(tb.x, tt.x, f) * b,
			"rz": s.z * 0.5 * lerpf(tb.y, tt.y, f) * b, "col": bot.lerp(top, f)})
	return out


## Geometry for one shape at one LOD, in the shape's PART frame.
## Returns {"groups": [{"tris": [[p,n,c]x3...], "cap": bool}], "pts": PackedVector3Array}
static func gen(sh: Dictionary, lod: int) -> Dictionary:
	var xf := Transform3D(Basis.from_euler(sh["rot"] * (PI / 180.0)), sh["c"])
	var groups: Array = []
	match str(sh["kind"]):
		"ell":
			groups.append({"tris": _ell(sh, lod, false), "cap": false})
		"dome":
			var d := _ell(sh, lod, true)
			groups.append({"tris": d[0], "cap": false})
			groups.append({"tris": d[1], "cap": true})
		"quad":
			groups.append({"tris": _quad(sh), "cap": false})
		_:
			var g := _tube(sh, lod)
			groups.append({"tris": g[0], "cap": false})
			if g[1].size() > 0:
				groups.append({"tris": g[1], "cap": true})
			if g[2].size() > 0:
				groups.append({"tris": g[2], "cap": true})
	var pts := PackedVector3Array()
	for g in groups:
		var moved: Array = []
		for t in g["tris"]:
			var mt := []
			for v in t:
				var p: Vector3 = xf * (v[0] as Vector3)
				mt.append([p, (xf.basis * (v[1] as Vector3)).normalized(), v[2]])
				pts.append(p)
			moved.append(mt)
		g["tris"] = moved
	return {"groups": groups, "pts": pts}


static func _wind(a: Array, b: Array, c: Array, out: Vector3) -> Array:
	var n := ((b[0] as Vector3) - (a[0] as Vector3)).cross((c[0] as Vector3) - (a[0] as Vector3))
	# Godot front faces are clockwise seen from outside: geometric normal points in.
	if n.dot(out) > 0.0:
		return [a, c, b]
	return [a, b, c]


static func _tube(sh: Dictionary, lod: int) -> Array:
	var n := lod_sides(sh, lod)
	var flat: bool = sh["kind"] == "box"
	var rings := rings_of(sh, lod)
	var off := PI / 4.0 if flat else PI / n * 0.5
	var k := SQ2 if flat else 1.0
	var verts: Array = []  # per ring: [pos...]
	var norms: Array = []
	for ri in rings.size():
		var r: Dictionary = rings[ri]
		var prev: Dictionary = rings[maxi(0, ri - 1)]
		var nxt: Dictionary = rings[mini(rings.size() - 1, ri + 1)]
		var dy := float(nxt["y"]) - float(prev["y"])
		var slope := 0.0
		if absf(dy) > 1e-5:
			slope = ((float(nxt["rx"]) + float(nxt["rz"])) - (float(prev["rx"]) + float(prev["rz"]))) * 0.5 / dy
		var vr := []
		var nr := []
		for i in n:
			var th := TAU * i / n + off
			var x := cos(th) * float(r["rx"]) * k
			var z := sin(th) * float(r["rz"]) * k
			vr.append(Vector3(x, r["y"], z))
			var h := Vector3(cos(th) / maxf(0.001, float(r["rx"])), 0, sin(th) / maxf(0.001, float(r["rz"]))).normalized()
			nr.append((h + Vector3(0, -slope, 0)).normalized())
		verts.append(vr)
		norms.append(nr)
	var side := []
	for ri in rings.size() - 1:
		var c0: Color = rings[ri]["col"]
		var c1: Color = rings[ri + 1]["col"]
		for i in n:
			var j := (i + 1) % n
			var a = [verts[ri][i], norms[ri][i], c0]
			var b = [verts[ri][j], norms[ri][j], c0]
			var c = [verts[ri + 1][j], norms[ri + 1][j], c1]
			var d = [verts[ri + 1][i], norms[ri + 1][i], c1]
			var mid: Vector3 = ((a[0] as Vector3) + (c[0] as Vector3)) * 0.5
			var out := Vector3(mid.x, 0, mid.z)
			if flat:
				var fn := Vector3(((a[0] as Vector3) + (b[0] as Vector3)).x, 0, ((a[0] as Vector3) + (b[0] as Vector3)).z).normalized()
				a = [a[0], fn, a[2]]; b = [b[0], fn, b[2]]; c = [c[0], fn, c[2]]; d = [d[0], fn, d[2]]
			side.append(_wind(a, b, c, out))
			side.append(_wind(a, c, d, out))
	var caps := [[], []]
	for e in (2 if sh.get("caps", true) else 0):
		var ri := 0 if e == 0 else rings.size() - 1
		var ny := -1.0 if e == 0 else 1.0
		var col: Color = rings[ri]["col"]
		var nn := Vector3(0, ny, 0)
		var vr: Array = verts[ri]
		if float(rings[ri]["rx"]) < 0.002 and float(rings[ri]["rz"]) < 0.002:
			continue
		for i in range(1, n - 1):
			caps[e].append(_wind([vr[0], nn, col], [vr[i], nn, col], [vr[i + 1], nn, col], nn))
	return [side, caps[0], caps[1]]


static func _ell(sh: Dictionary, lod: int, dome: bool) -> Array:
	var s: Vector3 = sh["s"]
	var nu := int(sh.get("nu", 8))
	var nv := int(sh.get("nv", 6))
	if lod == 1:
		nu = maxi(5, nu - 2)
		nv = maxi(2 if dome else 3, nv - 2)
	var rx := s.x * 0.5
	var rz := s.z * 0.5
	var ry := s.y if dome else s.y * 0.5
	var jaw := float(sh.get("jaw", 1.0))
	var chin := float(sh.get("chin", 0.0))
	var top: Color = sh["color"]
	var bot: Color = sh["bot"]
	var span := PI * 0.5 if dome else PI
	var grid: Array = []
	for j in nv + 1:
		var ph := span * j / nv
		var y := cos(ph)
		var r := sin(ph)
		var row := []
		for i in nu:
			var th := TAU * i / nu + PI * 0.5
			var x := cos(th) * r
			var z := sin(th) * r
			var kx := 1.0
			if y < 0.0:
				kx = lerpf(1.0, jaw, -y)
			var p := Vector3(x * rx * kx, y * ry, z * rz * kx)
			if y < 0.0 and z > 0.0:
				p.z += chin * (-y) * z * rz
			var nrm := Vector3(p.x / (rx * rx), p.y / (ry * ry), p.z / (rz * rz)).normalized()
			var t := (y + 1.0) * 0.5 if not dome else y
			row.append([p, nrm, bot.lerp(top, clampf(t, 0.0, 1.0))])
		grid.append(row)
	var tris := []
	for j in nv:
		for i in nu:
			var i2 := (i + 1) % nu
			var a = grid[j][i]; var b = grid[j][i2]; var c = grid[j + 1][i2]; var d = grid[j + 1][i]
			var out: Vector3 = ((a[1] as Vector3) + (c[1] as Vector3))
			if j > 0:
				tris.append(_wind(a, b, c, out))
			if not (j == nv - 1 and not dome):
				tris.append(_wind(a, c, d, out))
	var cap := []
	if dome:
		var row: Array = grid[nv]
		var nn := Vector3(0, -1, 0)
		for i in range(1, nu - 1):
			cap.append(_wind([row[0][0], nn, bot], [row[i][0], nn, bot], [row[i + 1][0], nn, bot], nn))
		return [tris, cap]
	return tris


static func _quad(sh: Dictionary) -> Array:
	var s: Vector3 = sh["s"]
	var hx := s.x * 0.5; var hy := s.y * 0.5
	var z := s.z * 0.5
	var nn := Vector3(0, 0, 1)
	var top: Color = sh["color"]; var bot: Color = sh["bot"]
	var tt: Vector2 = sh["tt"]; var tb: Vector2 = sh["tb"]
	var a = [Vector3(-hx * tb.x, -hy, z), nn, bot]
	var b = [Vector3(hx * tb.x, -hy, z), nn, bot]
	var c = [Vector3(hx * tt.x, hy, z), nn, top]
	var d = [Vector3(-hx * tt.x, hy, z), nn, top]
	return [_wind(a, b, c, nn), _wind(a, c, d, nn)]


# ---------------------------------------------------------------- containment

static func inside(p_local: Vector3, sh: Dictionary, tol := 0.003) -> bool:
	var q: Vector3 = sh["_inv"] * p_local
	match str(sh["kind"]):
		"quad":
			return false
		"ell", "dome":
			var s: Vector3 = sh["s"]
			var rx := s.x * 0.5 + tol; var rz := s.z * 0.5 + tol
			var ry := (s.y if sh["kind"] == "dome" else s.y * 0.5) + tol
			if sh["kind"] == "dome" and q.y < -tol:
				return false
			if q.y < 0.0:
				var kx := lerpf(1.0, float(sh.get("jaw", 1.0)), clampf(-q.y / ry, 0.0, 1.0))
				rx *= kx; rz *= kx
			return (q.x / rx) * (q.x / rx) + (q.y / ry) * (q.y / ry) + (q.z / rz) * (q.z / rz) <= 1.0
		_:
			var rings: Array = sh["_rings0"]
			var y0 := float(rings[0]["y"]); var y1 := float(rings[rings.size() - 1]["y"])
			if q.y < minf(y0, y1) - tol or q.y > maxf(y0, y1) + tol:
				return false
			var rx := 0.0; var rz := 0.0
			for i in rings.size() - 1:
				var a: Dictionary = rings[i]; var b: Dictionary = rings[i + 1]
				var lo := minf(a["y"], b["y"]); var hi := maxf(a["y"], b["y"])
				if q.y >= lo - tol and q.y <= hi + tol:
					var f := clampf((q.y - float(a["y"])) / maxf(1e-5, float(b["y"]) - float(a["y"])), 0.0, 1.0)
					rx = maxf(rx, lerpf(a["rx"], b["rx"], f)); rz = maxf(rz, lerpf(a["rz"], b["rz"], f))
			rx += tol; rz += tol
			if sh["kind"] == "box":
				return absf(q.x) <= rx and absf(q.z) <= rz
			return (q.x / rx) * (q.x / rx) + (q.z / rz) * (q.z / rz) <= 1.0


## Prepare, cull, and fit shapes for one LOD. rest: part -> {"bone", "xf"}.
static func prepare(shapes: Array, lod: int, rest: Dictionary) -> void:
	for sh in shapes:
		var g := gen(sh, lod)
		sh["_g%d" % lod] = g
		if not sh.has("_inv"):
			sh["_inv"] = Transform3D(Basis.from_euler(sh["rot"] * (PI / 180.0)), sh["c"]).affine_inverse()
			sh["_rings0"] = rings_of(sh, 0) if not (sh["kind"] in ["ell", "dome", "quad"]) else []
			var xf: Transform3D = rest[sh["part"]]["xf"]
			sh["_xf"] = xf
			sh["_xfi"] = xf.affine_inverse()
	# body-space bounding spheres
	for sh in shapes:
		var g: Dictionary = sh["_g%d" % lod]
		var pts: PackedVector3Array = g["pts"]
		var cen := Vector3.ZERO
		for p in pts:
			cen += p
		cen /= maxf(1.0, pts.size())
		var r := 0.0
		for p in pts:
			r = maxf(r, p.distance_to(cen))
		sh["_bc%d" % lod] = (sh["_xf"] as Transform3D) * cen
		sh["_br%d" % lod] = r
	# whole shapes sealed inside a bigger one on the same part
	for a in shapes:
		a["_hid%d" % lod] = false
		if a["ess"] and a["kind"] == "ell":
			continue
		var pa: PackedVector3Array = a["_g%d" % lod]["pts"]
		for b in shapes:
			if b == a or b["part"] != a["part"] or float(b["area"]) <= float(a["area"]) or b.get("_hid%d" % lod, false):
				continue
			if (a["_bc%d" % lod] as Vector3).distance_to(b["_bc%d" % lod]) > float(a["_br%d" % lod]) + float(b["_br%d" % lod]):
				continue
			var all_in := true
			for p in pa:
				if not inside(p, b):
					all_in = false
					break
			if all_in:
				a["_hid%d" % lod] = true
				break
	# buried end caps (any part, tested in body rest space)
	for a in shapes:
		var tris := 0
		for g in a["_g%d" % lod]["groups"]:
			g["on"] = true
			if g["cap"]:
				for b in shapes:
					if b == a or b.get("_hid%d" % lod, false):
						continue
					if (a["_bc%d" % lod] as Vector3).distance_to(b["_bc%d" % lod]) > float(a["_br%d" % lod]) + float(b["_br%d" % lod]):
						continue
					var all_in := true
					for t in g["tris"]:
						for v in t:
							var pb: Vector3 = (b["_xfi"] as Transform3D) * ((a["_xf"] as Transform3D) * (v[0] as Vector3))
							if not inside(pb, b):
								all_in = false
								break
						if not all_in:
							break
					if all_in:
						g["on"] = false
						break
			if g["on"]:
				tris += g["tris"].size()
		a["_t%d" % lod] = 0 if a["_hid%d" % lod] else tris


static func fit(shapes: Array, lod: int, cap: int) -> Array:
	var ranked := shapes.duplicate()
	if lod == 1:
		ranked.sort_custom(func(x, y):
			if x["ess"] != y["ess"] and (x["kind"] == "ell" or y["kind"] == "ell"):
				return x["kind"] == "ell"
			return x["area"] > y["area"])
	else:
		ranked.sort_custom(func(x, y):
			if x["ess"] != y["ess"]:
				return x["ess"]
			if x["main"] != y["main"]:
				return x["main"]
			return x["area"] > y["area"])
	var out: Array = []
	var n := 0
	for b in ranked:
		var t := int(b["_t%d" % lod])
		if t == 0:
			continue
		if lod == 1 and float(b["area"]) < 0.012 and b["kind"] != "ell":
			continue
		if n + t > cap:
			continue
		out.append(b)
		n += t
	out.sort_custom(func(x, y): return x["order"] < y["order"])
	return out


static func count(list: Array, lod: int) -> int:
	var n := 0
	for b in list:
		n += int(b["_t%d" % lod])
	return n


static func commit(list: Array, lod: int, rest: Dictionary) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var weights := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
	for sh in list:
		var xf: Transform3D = sh["_xf"]
		var bones := PackedInt32Array([int(rest[sh["part"]]["bone"]), 0, 0, 0])
		for g in sh["_g%d" % lod]["groups"]:
			if not g["on"]:
				continue
			for t in g["tris"]:
				for v in t:
					st.set_normal((xf.basis * (v[1] as Vector3)).normalized())
					st.set_color(v[2])
					st.set_bones(bones)
					st.set_weights(weights)
					st.add_vertex(xf * (v[0] as Vector3))
	return st.commit()
