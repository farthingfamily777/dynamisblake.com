extends SceneTree
## Headless checks for the low-poly people: poly budget per LOD (Ocarina of Time
## Young Link reference: ~726 tris close, ~434 far), one merged skinned mesh per
## LOD, a working rig, and every gear piece on/off.
## Run: godot --headless --path godot --script res://scripts/character_tests.gd

const LowPoly = preload("res://art/lowpoly_character.gd")
const Hero = preload("res://art/hero_model.gd")
const Wardrobe = preload("res://scripts/wardrobe.gd")

var passed := 0
var failed := 0


func ok(cond: bool, what: String) -> void:
	if cond:
		passed += 1
		print("  PASS  ", what)
	else:
		failed += 1
		print("  FAIL  ", what)


func _init() -> void:
	var root := Node3D.new()
	get_root().add_child.call_deferred(root)
	var w := Wardrobe.new()
	w.load_config()
	var rows: Array = []
	# Hero: starting gear with each weapon, fully dressed, and bare.
	for weapon in ["staff", "sword", "crossbow"]:
		var hero := CharacterBody3D.new()
		root.add_child(hero)
		Hero.build(hero, w.start, weapon)
		rows.append(["hero start gear + " + weapon, hero.get_node("Body")])
	var full := Wardrobe.new()
	full.load_config()
	full.dress_me()
	for weapon in ["staff", "sword", "crossbow"]:
		var h2 := CharacterBody3D.new()
		root.add_child(h2)
		Hero.build(h2, full.equipped, weapon)
		rows.append(["hero Dress Me (all slots) + " + weapon, h2.get_node("Body")])
	var bare := CharacterBody3D.new()
	root.add_child(bare)
	Hero.build(bare, {}, "")
	rows.append(["hero, all gear off", bare.get_node("Body")])
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for role in ["guard", "sailor", "merchant", "banker", "townsfolk"]:
		for i in 3:
			var n := Node3D.new()
			root.add_child(n)
			rows.append(["%s %d" % [role, i + 1], LowPoly.build(n, LowPoly.random_params(role, rng))])
	# Mage, Thief, Warrior starting kits with their class looks.
	var HC = load("res://scripts/hero_class.gd")
	for cls in ["mage", "thief", "warrior"]:
		var hc := CharacterBody3D.new()
		root.add_child(hc)
		var info: Dictionary = HC.CLASSES[cls]
		var look: Dictionary = (info["look"] as Dictionary).duplicate()
		look["tints"] = info["tints"]
		Hero.build(hc, HC.gear_for(cls), info["weapon"], look)
		rows.append(["class kit: " + cls, hc.get_node("Body")])
	var mx0 := 0
	var mx1 := 0
	print("\nTRIANGLES (LOD0 close / LOD1 far):")
	for r in rows:
		var b: Node3D = r[1]
		var t0 := int(b.get_meta("tris_lod0"))
		var t1 := int(b.get_meta("tris_lod1"))
		mx0 = maxi(mx0, t0)
		mx1 = maxi(mx1, t1)
		print("  %-40s %4d / %4d   (full detail would be %d)" % [r[0], t0, t1, int(b.get_meta("tris_wanted"))])
		var skel: Skeleton3D = b.get_node("Skel")
		var lod0: MeshInstance3D = skel.get_node("LOD0")
		var lod1: MeshInstance3D = skel.get_node("LOD1")
		# Real counts from the committed meshes, not just the bookkeeping.
		var real0: int = lod0.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3
		var real1: int = lod1.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3
		if real0 != t0 or real1 != t1:
			ok(false, "%s mesh tris match (%d/%d)" % [r[0], real0, real1])
	var mx2 := 0
	for r in rows:
		mx2 = maxi(mx2, int((r[1] as Node3D).get_meta("tris_lod2")))
	print("  LOD2 (Low far) max: %d" % mx2)
	var qb: Node3D = rows[0][1]
	LowPoly.quality = "low"
	LowPoly.apply_quality(qb)
	var sk: Node = qb.get_node("Skel")
	var low_ok: bool = not sk.get_node("LOD0").visible and sk.get_node("LOD1").visibility_range_end == 10.0 and sk.get_node("LOD2").visibility_range_end == 30.0 and qb.get_node("Imp").visibility_range_begin == 30.0
	LowPoly.quality = "high"
	LowPoly.apply_quality(qb)
	ok(mx2 <= LowPoly.LOD2_CAP, "LOD2 (Low far) never over %d tris (max %d)" % [LowPoly.LOD2_CAP, mx2])
	ok(low_ok, "Low quality: LOD1 close (<=450), LOD2 to 30 m, sprite beyond 30 m")
	ok(mx0 <= LowPoly.LOD0_CAP, "LOD0 never over %d tris (max %d)" % [LowPoly.LOD0_CAP, mx0])
	ok(mx1 <= LowPoly.LOD1_CAP, "LOD1 never over %d tris (max %d)" % [LowPoly.LOD1_CAP, mx1])
	var hb: Node3D = rows[3][1]
	ok(int(hb.get_meta("tris_lod0")) >= 690, "fully geared hero is in the OoT range (~700-760)")
	ok(int(hb.get_meta("tris_lod1")) >= 380, "far hero is in the OoT far range (~400-450)")
	var skel0: Skeleton3D = hb.get_node("Skel")
	ok(skel0.get_bone_count() == 10, "10-bone rig")
	ok(skel0.get_node("LOD0").mesh.get_surface_count() == 1 and skel0.get_node("LOD1").mesh.get_surface_count() == 1, "one merged surface per LOD (one draw call)")
	ok(skel0.get_node("LOD0").visibility_range_end > 0.0 and skel0.get_node("LOD1").visibility_range_begin > 0.0, "distance LOD swap set")
	# Walk cycle moves legs opposite and bends the swing knee.
	LowPoly.animate(hb, 0.0, 1.0, 0.0)
	var ll: Node3D = hb.get_node("LegL"); var lr: Node3D = hb.get_node("LegR")
	ok(absf(ll.rotation.x) < 0.05 and absf(lr.rotation.x) < 0.05, "legs pass under the body at phase 0")
	ok(hb.get_node("LegL/ShinL").rotation.x > 0.5, "swing knee bends while passing")
	LowPoly.animate(hb, PI / 2, 1.0, 0.0)
	ok(ll.rotation.x < -0.4 and lr.rotation.x > 0.25, "left heel reaches forward, right leg pushes back")
	ok(hb.get_node("ArmR").rotation.x < -0.3, "right arm swings forward with left leg")
	# Every slot type can be taken off and put back.
	var w2 := Wardrobe.new()
	w2.load_config()
	w2.dress_me()
	var n_on := w2.equipped.size()
	for sl in w2.equipped.keys():
		w2.take_off(sl)
	ok(n_on >= 15 and w2.equipped.is_empty(), "all %d worn pieces come off" % n_on)
	print("\nRESULTS: %d passed, %d failed" % [passed, failed])
	print("ALL PASSED" if failed == 0 else "SOME FAILED")
	quit(0 if failed == 0 else 1)
