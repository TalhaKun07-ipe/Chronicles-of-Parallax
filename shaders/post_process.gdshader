shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// Spacetime Dimensional Shockwave
uniform float shockwave_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 shockwave_center = vec2(0.5, 0.5);
uniform float shockwave_size = 0.65;
uniform float shockwave_thickness = 0.09;
uniform float shockwave_force = 0.045;

// Vignette controls
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.32;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.65;
uniform vec4 vignette_color : source_color = vec4(0.03, 0.02, 0.01, 1.0);

// Lens Chromatic Aberration
uniform float aberration_amount : hint_range(0.0, 0.02) = 0.0018;

// Film Grain
uniform float grain_amount : hint_range(0.0, 0.1) = 0.022;
uniform float grain_speed : hint_range(0.0, 30.0) = 12.0;

// Color Grading & Tonality
uniform float contrast : hint_range(0.5, 1.5) = 1.05;
uniform float brightness : hint_range(-0.2, 0.2) = 0.01;
uniform float saturation : hint_range(0.0, 2.0) = 1.08;
uniform vec4 warm_tint : source_color = vec4(1.03, 1.0, 0.96, 1.0);

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// 1. Dimensional Shockwave Refraction Ripple
	float shock_chroma = 0.0;
	if (shockwave_progress > 0.001 && shockwave_progress < 0.999) {
		float current_radius = shockwave_progress * shockwave_size;
		vec2 diff = uv - shockwave_center;
		float dist_from_center = length(diff);
		float ring = smoothstep(current_radius - shockwave_thickness, current_radius, dist_from_center) *
		             smoothstep(current_radius + shockwave_thickness, current_radius, dist_from_center);
		float fade = 1.0 - shockwave_progress;
		if (dist_from_center > 0.0001) {
			vec2 warp_dir = diff / dist_from_center;
			uv -= warp_dir * ring * shockwave_force * fade;
		}
		shock_chroma = ring * fade * 0.008;
	}

	vec2 centered = uv - 0.5;
	float dist = length(centered);

	// 2. Radial Chromatic Aberration (peripheral + shockwave)
	float ca_offset = dist * dist * aberration_amount + shock_chroma;
	vec2 r_uv = uv - centered * ca_offset;
	vec2 b_uv = uv + centered * ca_offset;

	float r = texture(screen_texture, r_uv).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, b_uv).b;
	vec3 color = vec3(r, g, b);

	// 3. Warm Vault Color Grade & Saturation
	color *= warm_tint.rgb;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, saturation);
	color = (color - 0.5) * contrast + 0.5 + brightness;

	// 4. Subtle Film Grain
	float grain_time = floor(TIME * grain_speed);
	float grain = (random(uv + vec2(grain_time * 0.13, grain_time * 0.27)) - 0.5) * grain_amount;
	color += grain;

	// 5. Smooth Cinematic Vignette
	float vignette = smoothstep(0.75, vignette_intensity * 0.4, dist);
	color = mix(vignette_color.rgb, color, mix(1.0, vignette, vignette_opacity));

	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
