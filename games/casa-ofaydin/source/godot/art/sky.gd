extends Object
# Compatibility-safe sky + light distance fog. No volumetric fog, SDFGI, or glow.
# Town within ~40m stays crisp and colorful; only the far horizon hazes.

static func setup(env: Environment, sun: DirectionalLight3D) -> void:
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	env.fog_density = 0.0028
	env.fog_sky_affect = 0.18
	env.fog_aerial_perspective = 0.15
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	env.adjustment_enabled = false
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.light_specular = 0.35
	apply(env, sun, 0.3, 0.6)


static func apply(env: Environment, sun: DirectionalLight3D, time_of_day: float, daylight: float) -> void:
	# 0 = midnight, 0.5 = noon. Dusk ~0.72-0.85, dawn ~0.15-0.28.
	var dusk := _band(time_of_day, 0.74, 0.88, 0.05)
	var dawn := _band(time_of_day, 0.14, 0.22, 0.05)
	var glow := maxf(dusk, dawn)
	var night := 1.0 - daylight

	# Morrowind daytime: pale blue-gray sky, readable local color.
	var top_day := Color(0.42, 0.62, 0.82)
	var top_dusk := Color(0.78, 0.48, 0.40)
	var top_night := Color(0.06, 0.07, 0.14)
	var hor_day := Color(0.72, 0.80, 0.88)
	var hor_dusk := Color(0.95, 0.70, 0.52)
	var hor_night := Color(0.10, 0.12, 0.20)

	var top := top_night.lerp(top_day, daylight).lerp(top_dusk, glow)
	var hor := hor_night.lerp(hor_day, daylight).lerp(hor_dusk, glow)
	var ground_h := Color(0.10, 0.12, 0.16).lerp(Color(0.45, 0.55, 0.52), daylight).lerp(Color(0.55, 0.38, 0.28), glow)
	var ground_b := Color(0.12, 0.14, 0.12)

	var psm: ProceduralSkyMaterial = env.sky.sky_material
	psm.sky_top_color = top
	psm.sky_horizon_color = hor
	psm.sky_curve = 0.08
	psm.ground_horizon_color = ground_h
	psm.ground_bottom_color = ground_b
	psm.ground_curve = 0.12
	psm.sun_angle_max = 28.0
	psm.sun_curve = 0.10

	env.background_color = hor
	env.ambient_light_color = Color(0.16, 0.18, 0.28).lerp(Color(0.62, 0.68, 0.75), daylight).lerp(Color(0.70, 0.48, 0.36), glow * 0.65)
	env.ambient_light_energy = 0.45 + daylight * 0.5
	# Cool daylight fog, warm but light dusk fog — density stays low so 40m is crisp.
	env.fog_light_color = Color(0.14, 0.16, 0.22).lerp(Color(0.70, 0.78, 0.86), daylight).lerp(Color(0.90, 0.65, 0.48), glow)
	env.fog_density = 0.0024 + night * 0.0030 + glow * 0.0016
	env.fog_sky_affect = 0.12 + glow * 0.12 + night * 0.08
	env.fog_light_energy = 0.9

	sun.rotation_degrees = Vector3(-(time_of_day * 360.0 - 90.0), 28, 0)
	sun.light_color = Color(0.55, 0.65, 0.90).lerp(Color(1.0, 0.97, 0.90), daylight).lerp(Color(1.0, 0.68, 0.42), glow)
	sun.light_energy = 0.10 + daylight * 1.05 + glow * 0.15


static func _band(t: float, a: float, b: float, fade: float) -> float:
	if t >= a and t <= b:
		return 1.0
	if t > a - fade and t < a:
		return (t - (a - fade)) / fade
	if t > b and t < b + fade:
		return 1.0 - (t - b) / fade
	return 0.0
