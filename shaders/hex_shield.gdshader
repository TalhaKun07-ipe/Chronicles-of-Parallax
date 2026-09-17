shader_type spatial;
render_mode blend_add, cull_disabled, depth_draw_never, unshaded;

// Translucent pulsating hex-grid forcefield for Axiom Warden.
uniform vec4 shield_color : source_color = vec4(0.3, 0.85, 1.0, 1.0);
uniform float hex_scale : hint_range(2.0, 40.0) = 12.0;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.0;
uniform float line_thickness : hint_range(0.01, 0.4) = 0.08;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.2;

varying vec3 world_norm;

vec2 hex_cell(vec2 p) {
	p.x *= 1.1547;
	vec2 a = fract(p) - 0.5;
	vec2 b = fract(p - vec2(0.5)) - 0.5;
	return dot(a, a) < dot(b, b) ? a : b;
}

void vertex() {
	world_norm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec2 h = hex_cell(UV * hex_scale);
	float dist = max(abs(h.x) * 1.5 + abs(h.y), abs(h.y) * 2.0);
	float edge = smoothstep(0.5 - line_thickness, 0.5, dist);

	float fresnel = pow(1.0 - clamp(dot(VIEW, world_norm), 0.0, 1.0), fresnel_power);
	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed);

	float alpha = clamp(edge * 0.75 + fresnel * 0.55, 0.0, 1.0) * pulse;
	ALBEDO = shield_color.rgb * alpha;
	EMISSION = shield_color.rgb * (1.2 + fresnel * 2.0) * alpha;
	ALPHA = alpha;
}
