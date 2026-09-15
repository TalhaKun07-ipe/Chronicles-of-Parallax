shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 stone_color : source_color = vec4(0.48, 0.38, 0.28, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.18, 0.14, 0.10, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.65, 0.54, 0.40, 1.0);

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
	bool is_top = abs(world_norm.y) > 0.7;
	vec2 uv = is_top ? world_pos.xz : (abs(world_norm.x) > 0.7 ? world_pos.zy : world_pos.xy);
	
	// Clean masonry grid dimensions
	vec2 block_size = is_top ? vec2(1.8, 1.8) : vec2(1.8, 0.75);
	float row = floor(uv.y / block_size.y);
	uv.x += mod(row, 2.0) * (block_size.x * 0.5);
	
	vec2 cell_id = floor(uv / block_size);
	vec2 cell_uv = fract(uv / block_size);
	
	// Crisp, anti-aliased mortar joints
	float seam_width = 0.035;
	float seam_x = 1.0 - smoothstep(0.0, seam_width, cell_uv.x) * smoothstep(0.0, seam_width, 1.0 - cell_uv.x);
	float seam_y = 1.0 - smoothstep(0.0, seam_width * 1.5, cell_uv.y) * smoothstep(0.0, seam_width * 1.5, 1.0 - cell_uv.y);
	float seam = clamp(seam_x + seam_y, 0.0, 1.0);
	
	// Crisp upper bevel highlight
	float bevel = smoothstep(0.88, 0.95, cell_uv.y) * (1.0 - seam_x);
	
	// Smooth, clean per-block variation (no noisy grain)
	float tint_var = mix(0.92, 1.06, hash21(cell_id));
	vec3 base = stone_color.rgb * tint_var;
	
	// Combine: base stone -> mortar seams -> bevel highlight
	vec3 col = mix(base, mortar_color.rgb, seam * 0.85);
	col = mix(col, highlight_color.rgb, bevel * 0.25);
	
	// Subtle vertical ambient grounding on walls
	if (!is_top) {
		float ground_shade = clamp(world_pos.y * 0.08 + 0.92, 0.85, 1.0);
		col *= ground_shade;
	}
	
	ALBEDO = col;
	ROUGHNESS = 0.75;
	SPECULAR = 0.15;
}
