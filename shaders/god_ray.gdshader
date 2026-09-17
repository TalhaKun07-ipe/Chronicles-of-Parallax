shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 ray_color : source_color = vec4(1.0, 0.92, 0.72, 0.28);
uniform float falloff_power : hint_range(1.0, 5.0) = 2.2;
uniform float speed : hint_range(0.0, 2.0) = 0.25;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// Vertical beam falloff (soft top origin, fading softly at bottom)
	float v_fade = pow(1.0 - UV.y, falloff_power) * smoothstep(0.0, 0.15, UV.y);
	
	// Horizontal soft edges
	float h_fade = smoothstep(0.0, 0.35, UV.x) * smoothstep(1.0, 0.65, UV.x);
	
	// Dynamic animated dust drift within the beam
	float n = noise(UV * vec2(3.0, 8.0) + vec2(TIME * speed * 0.1, -TIME * speed * 0.3));
	float dust = mix(0.75, 1.25, n);
	
	float alpha = v_fade * h_fade * ray_color.a * dust;
	ALBEDO = ray_color.rgb;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
