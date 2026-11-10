extends Object
# Tiny procedural textures (cached) for a Morrowind-like weathered look.
# Compatibility-renderer safe: ImageTexture only, no large assets.

static var _cache: Dictionary = {}

static func get_tex(kind: String) -> ImageTexture:
	if _cache.has(kind):
		return _cache[kind]
	var img: Image
	match kind:
		"dirt":
			img = _dirt()
		"cobble":
			img = _cobble()
		"plaster":
			img = _plaster(false)
		"peel":
			img = _plaster(true)
		"wood":
			img = _wood(Color(0.32, 0.2, 0.12), Color(0.18, 0.11, 0.07))
		"wood_fine":
			img = _wood(Color(0.42, 0.3, 0.18), Color(0.28, 0.18, 0.1))
		"rust":
			img = _rust()
		"tin":
			img = _tin()
		"rock":
			img = _rock(Color(0.28, 0.26, 0.24), Color(0.16, 0.15, 0.14))
		"clean_stone":
			img = _rock(Color(0.55, 0.5, 0.42), Color(0.4, 0.36, 0.3))
		"sand":
			img = _dirt_colored(Color(0.36, 0.3, 0.2), Color(0.22, 0.18, 0.12))
		"moss":
			img = _dirt_colored(Color(0.28, 0.32, 0.18), Color(0.16, 0.2, 0.1))
		"fabric":
			img = _fabric()
		"leather":
			img = _leather()
		"trim":
			img = _trim()
		"water":
			img = _water()
		"net":
			img = _net()
		"thatch":
			img = _thatch()
		_:
			img = _dirt()
	var tex := ImageTexture.create_from_image(img)
	_cache[kind] = tex
	return tex


static func mat(kind: String, tint: Color = Color(1, 1, 1), rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = get_tex(kind)
	m.roughness = rough
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.uv1_scale = Vector3(1, 1, 1)
	return m


static func unlit_em(color: Color, energy := 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 1.0
	return m


static func _hash(x: int, y: int, seed: int) -> float:
	var n := sin(float(x) * 12.9898 + float(y) * 78.233 + float(seed) * 45.164) * 43758.5453
	return n - floor(n)


static func _vhash(x: int, y: int, seed: int) -> float:
	# smooth-ish 2d value noise
	var x0 := int(floor(float(x) / 8.0))
	var y0 := int(floor(float(y) / 8.0))
	var fx := (float(x) / 8.0) - float(x0)
	var fy := (float(y) / 8.0) - float(y0)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _hash(x0, y0, seed)
	var b := _hash(x0 + 1, y0, seed)
	var c := _hash(x0, y0 + 1, seed)
	var d := _hash(x0 + 1, y0 + 1, seed)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


static func _img() -> Image:
	return Image.create(128, 128, false, Image.FORMAT_RGBA8)


static func _dirt() -> Image:
	return _dirt_colored(Color(0.22, 0.16, 0.1), Color(0.12, 0.09, 0.06))


static func _dirt_colored(a: Color, b: Color) -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var n := _vhash(x, y, 3) * 0.7 + _vhash(x * 2, y * 2, 9) * 0.3
			var crack := 0.0
			var c1 := _hash(x, y / 3, 11)
			if c1 > 0.97:
				crack = 0.35
			var col := a.lerp(b, n)
			col = col.darkened(crack)
			# faint pebbles
			if _hash(x, y, 19) > 0.985:
				col = col.lightened(0.12)
			img.set_pixel(x, y, col)
	return img


static func _cobble() -> Image:
	var img := _img()
	var mortar := Color(0.22, 0.18, 0.14)
	for y in 128:
		for x in 128:
			var row := int(y / 16)
			var ox := 8 if (row % 2) == 1 else 0
			var cx := int((x + ox) / 20)
			var cy := row
			var lx := (x + ox) % 20
			var ly := y % 16
			var edge := 0.0
			if lx < 2 or lx > 17 or ly < 2 or ly > 13:
				edge = 1.0
			var n := _hash(cx, cy, 5) * 0.2 + _vhash(x, y, 6) * 0.15
			var base := Color(0.28 + n, 0.24 + n * 0.8, 0.2 + n * 0.5)
			# wear
			base = base.lerp(Color(0.2, 0.18, 0.14), _vhash(x, y, 21) * 0.35)
			if edge > 0.0:
				img.set_pixel(x, y, mortar.darkened(_hash(x, y, 1) * 0.2))
			else:
				img.set_pixel(x, y, base)
	return img


static func _plaster(peel: bool) -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var n := _vhash(x, y, 7)
			var col := Color(0.45, 0.38, 0.28).lerp(Color(0.32, 0.26, 0.18), n)
			# stains
			col = col.lerp(Color(0.24, 0.2, 0.14), _vhash(x, y / 2, 12) * 0.4)
			if peel and (_vhash(x, y, 30) > 0.62):
				# peeled to darker under-layer / wood
				col = Color(0.28, 0.18, 0.1).lerp(Color(0.18, 0.12, 0.08), _hash(x, y, 4))
			# cracks
			if _hash(x, int(y / 2), 41) > 0.98:
				col = col.darkened(0.3)
			img.set_pixel(x, y, col)
	return img


static func _wood(a: Color, b: Color) -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var plank := int(x / 16)
			var px := x % 16
			var grain := sin((float(y) + _hash(plank, 0, 2) * 40.0) * 0.35 + float(px) * 0.15) * 0.5 + 0.5
			grain = lerp(grain, _vhash(x, y, 8), 0.3)
			var col := a.lerp(b, grain)
			if px < 1 or px > 14:
				col = col.darkened(0.35)
			# knots
			if _hash(plank, int(y / 18), 3) > 0.92 and absf(px - 8) < 3:
				col = col.darkened(0.25)
			img.set_pixel(x, y, col)
	return img


static func _rust() -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var n := _vhash(x, y, 14)
			var col := Color(0.28, 0.16, 0.08).lerp(Color(0.45, 0.22, 0.08), n)
			col = col.lerp(Color(0.14, 0.12, 0.1), _vhash(x / 2, y, 2) * 0.5)
			if _hash(x, y, 9) > 0.96:
				col = Color(0.55, 0.3, 0.1)
			img.set_pixel(x, y, col)
	return img


static func _tin() -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var corrug := absf(sin(float(x) * 0.8)) * 0.12
			var n := _vhash(x, y, 18)
			var col := Color(0.38 + corrug, 0.34 + corrug * 0.6, 0.28)
			col = col.lerp(Color(0.32, 0.18, 0.08), n * 0.55)  # rust patches
			if int(y / 32) != int((y - 1) / 32):
				col = col.darkened(0.2)  # seams
			img.set_pixel(x, y, col)
	return img


static func _rock(a: Color, b: Color) -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var n := _vhash(x, y, 4) * 0.6 + _vhash(x * 3, y * 3, 5) * 0.4
			var col := a.lerp(b, n)
			if _hash(x, y, 22) > 0.984:
				col = col.lightened(0.1)
			img.set_pixel(x, y, col)
	return img


static func _fabric() -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var n := _vhash(x, y, 10)
			var fold := 0.5 + 0.5 * sin(float(x) * 0.28 + n * 1.5)
			var base := Color(0.27, 0.20, 0.13)
			var col := base.lerp(Color(0.18, 0.13, 0.08), n * 0.45)
			col = col.lerp(Color(0.32, 0.24, 0.15), fold * 0.25)
			# faint wear spots, no bold stripes
			if _hash(x, y, 21) > 0.97:
				col = col.darkened(0.12)
			img.set_pixel(x, y, col)
	return img


static func _leather() -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var n := _vhash(x, y, 16)
			var col := Color(0.22, 0.16, 0.1).lerp(Color(0.34, 0.22, 0.12), n)
			img.set_pixel(x, y, col)
	return img


static func _trim() -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var g := 0.5 + 0.5 * sin(float(x) * 0.5) * sin(float(y) * 0.5)
			var col := Color(0.42, 0.32, 0.14).lerp(Color(0.22, 0.16, 0.07), g)
			if (x + y) % 9 == 0:
				col = col.lightened(0.12)
			img.set_pixel(x, y, col)
	return img


static func _water() -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var w := 0.5 + 0.5 * sin(float(x) * 0.2 + float(y) * 0.08)
			w = lerp(w, _vhash(x, y, 1), 0.35)
			var col := Color(0.12, 0.16, 0.14).lerp(Color(0.2, 0.22, 0.18), w)
			img.set_pixel(x, y, col)
	return img


static func _net() -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cord := Color(0.3, 0.24, 0.16, 1)
	for i in 64:
		for t in 2:
			img.set_pixel(i, (i + t * 8) % 64, cord)
			img.set_pixel((i + t * 8) % 64, i, cord)
			if i % 8 == 0:
				for k in 64:
					img.set_pixel(i, k, cord)
					img.set_pixel(k, i, cord)
	return img


static func _thatch() -> Image:
	var img := _img()
	for y in 128:
		for x in 128:
			var strand := _hash(x, y / 2, 2)
			var col := Color(0.36, 0.28, 0.12).lerp(Color(0.22, 0.16, 0.08), strand)
			if int(x / 3) % 2 == 0:
				col = col.darkened(0.08)
			img.set_pixel(x, y, col)
	return img
