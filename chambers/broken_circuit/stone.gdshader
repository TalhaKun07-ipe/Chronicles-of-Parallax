shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// 1. Clean Warm Sandstone Palette (Crisp & Elegant Ancient Architecture)
uniform vec4 stone_color : source_color = vec4(0.58, 0.46, 0.33, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.18, 0.12, 0.08, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.85, 0.73, 0.55, 1.0);

// 2. Bevel & Sunlit Rim Controls
uniform float bevel_strength : hint_range(0.0, 1.0) = 0.45;
uniform float sunlit_rim : hint_range(0.0, 1.0) = 0.35;
uniform vec3 sun_dir = vec3(-0.6, 0.75, -0.3);

varying vec3 world_pos;
varying vec3 world_norm;

// Fast procedural hash for smooth per-block tone shifts
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
	// Triplanar projection for seamless slab mapping
	bool is_top = world_norm.y > 0.6;
	bool is_side_x = abs(world_norm.x) > 0.6;
	vec2 uv = is_top ? world_pos.xz : (is_side_x ? world_pos.zy : world_pos.xy);
	
	// 1. Clean Architectural Block Grid (Square floor slabs, rectangular wall masonry)
	vec2 block_size = is_top ? vec2(1.6, 1.6) : vec2(1.6, 0.8);
	float row = floor(uv.y / block_size.y);
	uv.x += mod(row, 2.0) * (block_size.x * 0.5);
	
	vec2 cell_id = floor(uv / block_size);
	vec2 cell_uv = fract(uv / block_size);
	
	// 2. Crisp, Clean Anti-Aliased Mortar Joints
	float seam_w = 0.038;
	float seam_x = 1.0 - smoothstep(0.0, seam_w, cell_uv.x) * smoothstep(0.0, seam_w, 1.0 - cell_uv.x);
	float seam_y = 1.0 - smoothstep(0.0, seam_w * 1.5, cell_uv.y) * smoothstep(0.0, seam_w * 1.5, 1.0 - cell_uv.y);
	float seam = clamp(seam_x + seam_y, 0.0, 1.0);
	
	// 3. Crisp Chiseled Edge Bevel Highlights (Upper & Left Borders)
	float bevel_top = smoothstep(0.86, 0.97, cell_uv.y) * (1.0 - seam_x);
	float bevel_left = smoothstep(0.03, 0.12, cell_uv.x) * smoothstep(0.0, 0.03, 1.0 - cell_uv.x) * (1.0 - seam_y);
	float total_bevel = clamp(bevel_top + bevel_left * 0.6, 0.0, 1.0);
	
	// 4. Subtle, Smooth Per-Block Warmth Variation (No mottled grain or dirty stains)
	float block_hash = hash21(cell_id);
	float tint_var = mix(0.94, 1.06, block_hash);
	vec3 base = stone_color.rgb * tint_var;
	
	// Floor slabs are slightly warmer and lighter for player readability
	if (is_top) {
		base *= 1.08;
	}
	
	// Combine: Base Sandstone -> Deep Mortar Seams -> Crisp Bevel Highlight
	vec3 col = mix(base, mortar_color.rgb, seam * 0.88);
	col = mix(col, highlight_color.rgb, total_bevel * bevel_strength);
	
	// 5. Sunlit Directional Edge Rim
	vec3 norm_sun = normalize(sun_dir);
	float sun_factor = max(dot(world_norm, norm_sun), 0.0);
	float rim = pow(1.0 - max(dot(VIEW, NORMAL), 0.0), 3.0) * sun_factor;
	col += highlight_color.rgb * rim * sunlit_rim * (1.0 - seam * 0.5);
	
	// 6. Smooth Vertical Grounding at Wall Base
	if (!is_top) {
		float ground_shade = clamp(world_pos.y * 0.07 + 0.93, 0.85, 1.0);
		col *= ground_shade;
	}
	
	ALBEDO = col;
	ROUGHNESS = 0.82;
	SPECULAR = 0.12;
}
