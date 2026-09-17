shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, unshaded;

// Expanding shockwave ring for boss slam/sweep telegraphs and impacts.
// Distinct from energy_conduit/hologram_bridge: this one reads a "progress" uniform
// driven from GDScript (0 = just spawned, 1 = about to despawn) instead of purely TIME,
// since the ring's radius/lifetime is already gameplay-driven by hazard.gd.

uniform vec4 core_color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform vec4 edge_color : source_color = vec4(0.4, 0.1, 0.02, 1.0);
uniform float emission_energy : hint_range(0.5, 8.0) = 3.2;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float distortion_speed : hint_range(0.0, 20.0) = 6.0;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(213.31, 371.79));
	p += dot(p, p + 27.19);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// UV.x wraps around the ring's circumference, UV.y around the tube cross-section.
	float wobble = hash21(vec2(floor(UV.x * 24.0), floor(TIME * distortion_speed))) * 0.15;

	// Crest brightens through the first half of life, then dims as it fades out.
	float crest = 1.0 - abs(progress - 0.35) * 1.3;
	crest = clamp(crest, 0.0, 1.0);

	// Cross-section falloff: bright core band down the middle of the tube, dimmer at the rim.
	// Fresnel is folded in so most of the visible surface still leans toward core_color
	// instead of sitting on the darker edge_color (which read as a dull muddy ring).
	float band = 1.0 - smoothstep(0.0, 1.0, abs(UV.y - 0.5) * 2.0 + wobble);
	float fresnel = pow(1.0 - clamp(dot(VIEW, NORMAL), 0.0, 1.0), 1.5);
	float core_weight = clamp(band + fresnel * 0.6, 0.0, 1.0);

	vec3 col = mix(edge_color.rgb, core_color.rgb, core_weight);
	// Only fade in the ring's very last moment, so it stays bright for almost its whole life
	// instead of visibly dulling out well before it actually despawns.
	float fade = 1.0 - smoothstep(0.9, 1.0, progress);

	// Keep the unshaded surface itself dark so EMISSION (which blooms) carries the color,
	// rather than a flat mid-brightness ALBEDO that reads as dull under scene lighting.
	ALBEDO = col * 0.08;
	EMISSION = col * emission_energy * (0.6 + crest * 0.9) * fade;
}
