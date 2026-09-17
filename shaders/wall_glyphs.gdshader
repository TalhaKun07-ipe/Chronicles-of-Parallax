shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

// Ancient geometric wall hieroglyphs that ignite with additive golden light.
// Uses blend_add with depth_draw_never so no opaque backing rectangle is drawn.

uniform vec4 lit_color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float lit : hint_range(0.0, 1.0) = 0.0;
uniform float emission_energy : hint_range(0.5, 6.0) = 2.0;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(217.31, 583.29));
	p += dot(p, p + 41.13);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell_uv = fract(UV * 3.0) - 0.5;
	float cell_id = hash21(floor(UV * 3.0));
	float ring = abs(length(cell_uv) - (0.22 + cell_id * 0.06));
	float glyph = 1.0 - smoothstep(0.0, 0.035, ring);
	float cross_line = 1.0 - smoothstep(0.0, 0.02, min(abs(cell_uv.x), abs(cell_uv.y)));
	glyph = clamp(glyph + cross_line * 0.5, 0.0, 1.0);

	// Edge falloff so the quad has soft circular bounds instead of square edges
	vec2 edge_dist = abs(UV - 0.5) * 2.0;
	float vignette = (1.0 - smoothstep(0.6, 1.0, edge_dist.x)) * (1.0 - smoothstep(0.6, 1.0, edge_dist.y));

	float pulse = 1.0 + sin(TIME * 1.6 + world_pos.x) * 0.15 * lit;
	vec3 col = lit_color.rgb * glyph * lit * emission_energy * pulse * vignette;

	ALBEDO = col;
}

