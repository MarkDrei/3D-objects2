class_name Stage
extends Node3D
## Photo studio for one object: backdrop sky, key and fill light, a floor that fades into the
## backdrop and a soft contact shadow. `fit(aabb)` adapts floor and shadows to the object.

var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var floor_mesh: MeshInstance3D
var contact: MeshInstance3D
var env: Environment


func _ready() -> void:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = preload("res://src/viewer/studio_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.88, 0.92)
	env.ambient_light_energy = 0.65
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.82
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = Vector3(-52, 38, 0)
	key_light.light_color = Color(1.0, 0.97, 0.92)
	key_light.light_energy = 1.2
	key_light.shadow_enabled = true
	key_light.shadow_blur = 2.5
	key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(key_light)

	fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.rotation_degrees = Vector3(-25, -140, 0)
	fill_light.light_color = Color(0.85, 0.9, 1.0)
	fill_light.light_energy = 0.45
	add_child(fill_light)

	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://src/viewer/floor.gdshader")
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	floor_mesh = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	floor_mesh.mesh = plane
	floor_mesh.material_override = floor_mat
	floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor_mesh)

	var blob_mat := ShaderMaterial.new()
	blob_mat.shader = preload("res://src/viewer/contact_shadow.gdshader")
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	contact = MeshInstance3D.new()
	contact.name = "ContactShadow"
	contact.mesh = quad
	contact.material_override = blob_mat
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	contact.position.y = 0.002
	add_child(contact)


## Sizes floor fade, contact shadow and shadow range to the object's bounding box.
func fit(aabb: AABB) -> void:
	var radius := maxf(aabb.size.length() / 2.0, 0.05)
	var foot := Vector2(aabb.size.x, aabb.size.z)
	contact.position = Vector3(aabb.get_center().x, 0.002, aabb.get_center().z)
	contact.scale = Vector3(foot.x * 1.25 + radius * 0.25, 1, foot.y * 1.25 + radius * 0.25)
	var floor_mat: ShaderMaterial = floor_mesh.material_override
	floor_mat.set_shader_parameter("fade_start", radius * 3.0)
	floor_mat.set_shader_parameter("fade_end", radius * 9.0)
	key_light.directional_shadow_max_distance = radius * 12.0
