shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// 1. Abyss Depth Gradient
uniform vec4 void_color : source_color = vec4(0.04, 0.02, 0.01, 1.0);
uniform vec4 mist_color : source_color = vec4(0.18, 0.12, 0.07, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.32, 0.22, 0.12, 1.0);

// 2. Mist Animation
uniform float mist_speed : hint_range(0.0, 2.0) = 0.25;
uniform float mist_density : hint_range(0.0, 1.0) = 0.65;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Slow rolling subterranean mist
	vec2 uv = world_pos.xz * 0.08;
	float t = TIME * mist_speed;
	float n1 = noise2d(uv + vec2(t * 0.3, t * 0.2));
	float n2 = noise2d(uv * 1.6 - vec2(t * 0.2, -t * 0.4));
	float mist = mix(n1, n2, 0.5) * mist_density;
	
	// Vertical depth fade (deeper = darker void)
	float depth = clamp((world_pos.y + 6.0) * 0.18, 0.0, 1.0);
	
	vec3 col = mix(void_color.rgb, mist_color.rgb, mist);
	col = mix(col, horizon_color.rgb, depth * 0.45);
	
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.05;
}
