class_name Mats
extends RefCounted
## Material factory. Materials are cached by their parameters, so equal parts share one material.

const PLUSH_SHADER := preload("res://src/kit/plush.gdshader")

static var _cache := {}


static func _std(key: String, setup: Callable) -> StandardMaterial3D:
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		setup.call(m)
		_cache[key] = m
	return _cache[key]


## Glossy car paint with a clear coat.
static func paint(color: Color, roughness := 0.22, metallic := 0.25) -> StandardMaterial3D:
	return _std("paint%s%s%s" % [color, roughness, metallic], func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.roughness = roughness
		m.metallic = metallic
		m.metallic_specular = 0.6
		m.clearcoat_enabled = true
		m.clearcoat = 1.0
		m.clearcoat_roughness = 0.05)


## Plastic / vinyl: smooth with a soft highlight.
static func plastic(color: Color, roughness := 0.4) -> StandardMaterial3D:
	return _std("plastic%s%s" % [color, roughness], func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.roughness = roughness)


## Matte surfaces: fabric, skin, rubber, low-poly style.
static func matte(color: Color, roughness := 0.85) -> StandardMaterial3D:
	return _std("matte%s%s" % [color, roughness], func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.roughness = roughness
		m.metallic_specular = 0.3)


## Matte material for faceted meshes: uses the per-facet brightness variation.
static func facet(color: Color, roughness := 0.85) -> StandardMaterial3D:
	return _std("facet%s%s" % [color, roughness], func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.roughness = roughness
		m.vertex_color_use_as_albedo = true
		m.metallic_specular = 0.3)


## Tinted window glass (opaque: reads as glass through its reflections).
static func glass(color := Color(0.06, 0.08, 0.11)) -> StandardMaterial3D:
	return _std("glass%s" % color, func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.roughness = 0.03
		m.metallic = 0.4
		m.metallic_specular = 1.0)


## See-through glass for lamps and light covers.
static func clear_glass(color := Color(1, 1, 1, 0.25)) -> StandardMaterial3D:
	return _std("cglass%s" % color, func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.02
		m.metallic_specular = 1.0)


static func chrome(color := Color(0.85, 0.86, 0.88)) -> StandardMaterial3D:
	return _std("chrome%s" % color, func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.metallic = 1.0
		m.roughness = 0.12)


## Light alloy for rims. Deliberately not metallic: metal takes almost no ambient light, so
## spokes in the shadow of the wheel arch turned black.
static func alloy(color := Color(0.78, 0.8, 0.83)) -> StandardMaterial3D:
	return _std("alloy%s" % color, func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.metallic = 0.0
		m.metallic_specular = 0.9
		m.roughness = 0.25)


static func rubber(color := Color(0.06, 0.06, 0.065)) -> StandardMaterial3D:
	return matte(color, 0.75)


## Self-lit material for lamps, lights and eye highlights.
static func glow(color: Color, energy := 1.5) -> StandardMaterial3D:
	return _std("glow%s%s" % [color, energy], func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy
		m.roughness = 0.2)


static func unshaded(color: Color) -> StandardMaterial3D:
	return _std("unshaded%s" % color, func(m: StandardMaterial3D) -> void:
		m.albedo_color = color
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if color.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA)


## Soft plush fabric (shader).
static func plush(color: Color, fuzz := 0.6, sheen := Color(1, 0.96, 0.9)) -> ShaderMaterial:
	var key := "plush%s%s%s" % [color, fuzz, sheen]
	if not _cache.has(key):
		var m := ShaderMaterial.new()
		m.shader = PLUSH_SHADER
		m.set_shader_parameter("albedo", color)
		m.set_shader_parameter("fuzz", fuzz)
		m.set_shader_parameter("sheen", sheen)
		_cache[key] = m
	return _cache[key]
