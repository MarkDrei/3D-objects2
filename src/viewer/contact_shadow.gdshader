// Soft dark blob under the object (ambient occlusion on the floor).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform float strength = 0.45;

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	ALBEDO = vec3(0.0);
	ALPHA = strength * pow(clamp(1.0 - r, 0.0, 1.0), 1.6);
}
