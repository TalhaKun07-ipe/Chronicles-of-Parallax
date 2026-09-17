shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// 1. Runic Glow Palette (Ancient Golden Sun Relic Energy)
uniform vec4 rune_core_color : source_color = vec4(1.0, 0.96, 0.82, 1.0);
uniform vec4 rune_glow_color : source_color = vec4(0.96, 0.68, 0.15, 1.0);
uniform vec4 rune_edge_color : source_color = vec4(0.72, 0.38, 0.05, 1.0);

// 2. Animation & Scanline Controls
uniform float emission_energy : hint_range(0.5, 6.0) = 2.6;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.4;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.28;
uniform float scanline_speed : hint_range(0.0, 10.0) = 3.0;
uniform float scanline_density : hint_range(1.0, 50.0) = 18.0;

varying vec3 world_pos;
varying vec3 world_norm;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_norm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	// 1. Rhythmic breathing pulse
	float pulse = 1.0 + sin(TIME * pulse_speed + world_pos.x * 0.8) * pulse_intensity;
	
	// 2. Holographic Scanline Grid
	float scanline = sin(world_pos.y * scanline_density - TIME * scanline_speed) * 0.5 + 0.5;
	scanline = pow(scanline, 2.5);
	
	// 3. Ancient Runic Geometric Lattice Pattern
	vec2 r_uv = fract(world_pos.xz * 2.5);
	float rune_glyph = step(0.82, max(r_uv.x, r_uv.y)) + step(0.88, abs(r_uv.x - r_uv.y));
	rune_glyph = clamp(rune_glyph, 0.0, 1.0);
	
	// 4. Fresnel Rim Glow
	float fresnel = pow(1.0 - max(dot(VIEW, NORMAL), 0.0), 2.2);
	
	// Color Blending: Deep Amber Base -> Pulsing Runic Glyphs -> White-Hot Core
	vec3 col = mix(rune_edge_color.rgb, rune_glow_color.rgb, 0.5 + scanline * 0.35);
	col = mix(col, rune_core_color.rgb, rune_glyph * 0.75 + scanline * 0.25);
	col += rune_glow_color.rgb * fresnel * 0.8;
	
	ALBEDO = col * 0.35;
	EMISSION = col * emission_energy * pulse; // HDR Bloom
	ROUGHNESS = 0.25;
	SPECULAR = 0.7;
}
