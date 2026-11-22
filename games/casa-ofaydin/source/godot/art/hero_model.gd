extends Object
# Hero: late-90s low-poly traveler (PS1 / FF7 / N64 style) built by
# art/lowpoly_character.gd. Worn gear comes from the wardrobe (data/clothing.json).
# No eyes are drawn; one brow line and the hood rim shape the face.

const LowPoly = preload("res://art/lowpoly_character.gd")

const LOOK := {
	"skin": Color(0.74, 0.56, 0.42),
	"hair": "shag",
	"hair_color": Color(0.26, 0.17, 0.10),
	"beard": true,
	"build": "broad",
	"height": 1.04,
	"under": Color(0.80, 0.74, 0.62),
	"shorts": Color(0.52, 0.44, 0.34),
	"weapon": "staff"
}


static func build(hero: CharacterBody3D, gear: Dictionary = {}, weapon := "staff", look: Dictionary = {}) -> void:
	var p := LOOK.duplicate()
	for k in look.keys():
		p[k] = look[k]
	p["gear"] = gear
	p["weapon"] = weapon
	var body := LowPoly.build(hero, p)
	# CharacterBody3D origin is the capsule center (1 m up); feet go to the ground.
	body.position = Vector3(0, -1.0, 0)
	# Models face +Z; the hero walks toward -Z.
	body.rotation.y = PI
