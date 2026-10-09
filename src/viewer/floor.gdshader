// Studio floor: takes light and shadows, fades into the backdrop towards the edge.
shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color = vec3(0.86, 0.87, 0.89);
uniform float fade_start = 6.0;
uniform float fade_end = 18.0;

varying float dist;

void vertex() {
	dist = length((MODEL_MATRIX * vec4(VERTEX, 1.0)).xz);
}

void fragment() {
	ALBEDO = color;
	ROUGHNESS = 0.6;
	SPECULAR = 0.25;
	ALPHA = 1.0 - smoothstep(fade_start, fade_end, dist);
}
