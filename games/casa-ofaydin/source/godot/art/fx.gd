extends Node
# Runtime art ticks: lighthouse, neon, animals, market crowd, paddle wheel, compass.

func _process(delta: float) -> void:
	var fx: Dictionary = get_meta("fx") if has_meta("fx") else {}
	var t := Time.get_ticks_msec() / 1000.0
	var head: Node3D = fx.get("lighthouse", null)
	if head:
		head.rotation_degrees.y = wrapf(head.rotation_degrees.y + 22.0 * delta, 0.0, 360.0)
	var neon: Label3D = fx.get("neon", null)
	if neon:
		var on := fmod(t, 2.4) > 0.18 or fmod(t * 7.3, 1.0) > 0.08
		var blackout := fmod(t, 7.0) > 6.35
		if blackout:
			on = false
		neon.modulate = Color(1.0, 0.45, 0.15, 1.0 if on else 0.15)
	var neon2: Label3D = fx.get("neon2", null)
	if neon2:
		var on2 := fmod(t + 0.7, 3.1) > 0.4
		neon2.modulate = Color(0.15, 0.95, 1.0, 1.0 if on2 else 0.2)
	var paddle: Node3D = fx.get("paddle", null)
	if paddle:
		paddle.rotation_degrees.z = wrapf(paddle.rotation_degrees.z + 50.0 * delta, 0.0, 360.0)
	var forge: MeshInstance3D = fx.get("forge", null)
	if forge and forge.material_override:
		var mat: StandardMaterial3D = forge.material_override
		mat.emission_energy_multiplier = 2.2 + sin(t * 6.0) * 0.8
	# flicker neon-tower cap strips slightly
	var towers: Array = fx.get("neon_towers", [])
	for tw in towers:
		var cap: MeshInstance3D = tw.get("cap", null)
		if cap and cap.material_override:
			var m: StandardMaterial3D = cap.material_override
			m.emission_energy_multiplier = 2.2 + sin(t * 8.0 + cap.position.x) * 0.5
	_wander(fx.get("animals", []), delta)
	_wander(fx.get("people", []), delta)
	_update_compass(get_parent())


func _wander(list: Array, delta: float) -> void:
	for a in list:
		a["t"] = a["t"] + delta * a["speed"]
		var n: Node3D = a["node"]
		var home: Vector3 = a["home"]
		var r: float = a["r"]
		var ang: float = a["t"]
		var target := home + Vector3(cos(ang) * r, 0, sin(ang * 0.7) * r * 0.6)
		n.position = n.position.lerp(target, clampf(delta * 1.8, 0.0, 1.0))
		var face := target - n.position
		if face.length() > 0.05:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(face.x, face.z), delta * 3.0)


func _update_compass(main: Node) -> void:
	if main == null or not main.has_meta("compass_pip"):
		return
	if not ("hero" in main):
		return
	var pip: ColorRect = main.get_meta("compass_pip")
	var hero: Node3D = main.hero
	var nx := clampf((hero.position.x + 20.0) / 40.0, 0.0, 1.0)
	var nz := clampf((hero.position.z + 24.0) / 40.0, 0.0, 1.0)
	pip.position = Vector2(18.0 + nx * 72.0 - 4.0, 14.0 + (1.0 - nz) * 72.0 - 4.0)
