shader_type canvas_item;

// Chrono-Warp Screen Shader for Degrees of Escape (4D Time Rewind)
// Inspired by Prince of Persia: The Sands of Time reverse-temporal visual filter.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float rewind_factor : hint_range(0.0, 1.0) = 0.0;
uniform vec2 warp_center = vec2(0.5, 0.5);
uniform float pinch_strength : hint_range(0.0, 0.1) = 0.035;
uniform float chromatic_dispersion : hint_range(0.0, 0.05) = 0.015;
uniform vec4 chrono_gold : source_color = vec4(1.15, 0.95, 0.55, 1.0);
uniform float scanline_density : hint_range(50.0, 400.0) = 220.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 diff = uv - warp_center;
	float dist = length(diff);

	// 1. Inward Radial Time Pinch (Sucking time back into the center)
	float pinch = (1.0 - smoothstep(0.0, 0.85, dist)) * pinch_strength * rewind_factor;
	vec2 warped_uv = uv - (diff * pinch);

	// 2. Chromatic Dispersion along radial lines
	vec2 ca_offset = diff * (chromatic_dispersion * rewind_factor);
	float r = texture(screen_texture, warped_uv - ca_offset).r;
	float g = texture(screen_texture, warped_uv).g;
	float b = texture(screen_texture, warped_uv + ca_offset).b;
	vec3 col = vec3(r, g, b);

	// 3. Golden Chrono Color Grade (Sands of Time golden-sepia tint)
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 sepia_tint = vec3(luma) * chrono_gold.rgb;
	col = mix(col, sepia_tint, rewind_factor * 0.65);

	// 4. Subtle Temporal Scanline Flutter
	float scanline = sin(SCREEN_UV.y * scanline_density + TIME * 18.0) * 0.04 * rewind_factor;
	col -= scanline;

	// 5. Golden Edge Vignette
	float vignette = smoothstep(0.35, 0.85, dist) * rewind_factor;
	col = mix(col, chrono_gold.rgb * 0.35, vignette * 0.7);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
