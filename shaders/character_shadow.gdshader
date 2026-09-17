shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 shadow_color : source_color = vec4(0.04, 0.03, 0.02, 0.60);
uniform float softness : hint_range(0.1, 1.0) = 0.85;

void fragment() {
	vec2 centered = UV - vec2(0.5, 0.5);
	float dist = length(centered * vec2(1.0, 1.3)); // Slightly elongated oval
	float alpha = smoothstep(0.5, 0.5 - softness * 0.45, dist);
	ALBEDO = shadow_color.rgb;
	ALPHA = alpha * shadow_color.a;
}
