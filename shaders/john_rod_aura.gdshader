shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

// Adaptive energy outline for John Rod's Sprite3D, keyed to active dimension.
uniform sampler2D sprite_tex : hint_default_transparent, filter_nearest;
uniform vec4 aura_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float aura_intensity : hint_range(0.0, 4.0) = 1.4;
uniform float pulse_speed : hint_range(0.0, 12.0) = 2.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.25;
uniform float edge_thickness : hint_range(0.0, 4.0) = 1.6;

void vertex() {
	// Full camera billboard calculation so Sprite3D faces the camera correctly with custom shader
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 tex = texture(sprite_tex, UV);
	if (tex.a < 0.08) {
		discard;
	}

	vec2 tex_size = vec2(textureSize(sprite_tex, 0));
	vec2 texel = (tex_size.x > 0.0) ? (edge_thickness / tex_size) : vec2(0.01);
	
	float edge = 0.0;
	edge += 1.0 - step(0.5, texture(sprite_tex, UV + vec2(texel.x, 0.0)).a);
	edge += 1.0 - step(0.5, texture(sprite_tex, UV - vec2(texel.x, 0.0)).a);
	edge += 1.0 - step(0.5, texture(sprite_tex, UV + vec2(0.0, texel.y)).a);
	edge += 1.0 - step(0.5, texture(sprite_tex, UV - vec2(0.0, texel.y)).a);
	edge += 1.0 - step(0.5, texture(sprite_tex, UV + texel).a);
	edge += 1.0 - step(0.5, texture(sprite_tex, UV - texel).a);
	edge = clamp(edge, 0.0, 1.0) * step(0.5, tex.a);

	float pulse = 1.0 - pulse_amount + pulse_amount * sin(TIME * pulse_speed);
	vec3 rim = aura_color.rgb * aura_intensity * pulse;

	ALBEDO = mix(tex.rgb, aura_color.rgb, edge * 0.85);
	EMISSION = rim * edge;
	ALPHA = tex.a;
}
