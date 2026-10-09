// Plush / velvet fabric: fine fibre noise in albedo and normal, lighter at grazing angles.
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec3 albedo : source_color = vec3(0.6, 0.4, 0.25);
uniform vec3 sheen : source_color = vec3(1.0, 0.95, 0.9);
uniform float sheen_amount = 0.45;
uniform float fuzz = 0.6;
uniform float fibre_scale = 90.0;

varying vec3 obj_pos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	// Object space corrected for the instance scale, so the fibres have the same size everywhere.
	obj_pos = VERTEX * vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz),
			length(MODEL_MATRIX[2].xyz));
}

void fragment() {
	vec3 p = obj_pos * fibre_scale;
	float n = noise(p) * 0.6 + noise(p * 2.7) * 0.4;
	float coarse = noise(obj_pos * 9.0);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - facing, 2.2);
	vec3 col = albedo * (1.0 - fuzz * 0.22 + fuzz * 0.3 * n) * (0.94 + 0.12 * coarse);
	ALBEDO = mix(col, mix(col, sheen, 0.55), rim * sheen_amount);
	vec3 jitter = vec3(noise(p + 11.0), noise(p + 23.0), noise(p + 37.0)) - 0.5;
	NORMAL = normalize(NORMAL + jitter * fuzz * 0.5);
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
}
