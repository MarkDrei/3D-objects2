// Studio backdrop: a soft grey gradient. Reflections (radiance pass) also see softboxes,
// which give glossy surfaces like car paint their highlights.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.78, 0.81, 0.86);
uniform vec3 horizon_color : source_color = vec3(0.90, 0.91, 0.93);
uniform vec3 bottom_color : source_color = vec3(0.90, 0.91, 0.93);
uniform float softbox_energy = 4.0;

float box(vec3 dir, vec3 center, vec2 half_size) {
	vec3 c = normalize(center);
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), c));
	vec3 up = cross(c, right);
	float d = dot(dir, c);
	if (d <= 0.0) return 0.0;
	vec2 uv = vec2(dot(dir, right), dot(dir, up)) / d;
	vec2 q = abs(uv) - half_size;
	float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
	return 1.0 - smoothstep(-0.02, 0.06, dist);
}

void sky() {
	float y = EYEDIR.y;
	vec3 col = y > 0.0 ? mix(horizon_color, top_color, pow(y, 0.6))
			: mix(horizon_color, bottom_color, pow(-y, 0.5));
	if (AT_CUBEMAP_PASS) {
		// Reflections see a darker studio, so glossy paint keeps its colour and gets contrast.
		col = y > 0.0 ? mix(vec3(0.34, 0.35, 0.37), vec3(0.62, 0.64, 0.68), smoothstep(0.0, 0.6, y))
				: mix(vec3(0.3, 0.3, 0.31), vec3(0.2, 0.2, 0.21), smoothstep(0.0, 0.3, -y));
		float l = box(EYEDIR, vec3(0.7, 0.8, 0.9), vec2(0.45, 0.3));
		l += box(EYEDIR, vec3(-0.9, 0.5, -0.4), vec2(0.25, 0.5)) * 0.6;
		l += box(EYEDIR, vec3(0.0, 1.0, 0.02), vec2(1.2, 0.12)) * 0.8;
		col += vec3(1.0, 0.99, 0.97) * l * softbox_energy;
	}
	COLOR = col;
}
