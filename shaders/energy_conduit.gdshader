shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// 1. Plasma Color Palette
uniform vec4 core_color : source_color = vec4(0.88, 0.98, 1.0, 1.0);
uniform vec4 plasma_color : source_color = vec4(0.20, 0.82, 0.86, 1.0);
uniform vec4 edge_color : source_color = vec4(0.06, 0.42, 0.62, 1.0);

// 2. Animation & Flow Controls
uniform float flow_speed : hint_range(0.0, 10.0) = 2.5;
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float emission_energy : hint_range(0.5, 5.0) = 2.4;
uniform float crackle_intensity : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_pos;
varying vec3 world_norm;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_norm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	// World-space linear flow along the X-axis (conduit traversal direction)
	vec2 uv = vec2(world_pos.x * 1.5, world_pos.y * 2.0 + world_pos.z * 2.0);
	
	// Dual scrolling plasma currents (counter-flowing for energetic turbulence)
	float t = TIME * flow_speed;
	float stream1 = noise2d(uv + vec2(-t, 0.0));
	float stream2 = noise2d(uv * 1.8 + vec2(-t * 1.4, 0.5));
	float plasma = mix(stream1, stream2, 0.5);
	
	// Rhythmic energetic breathing pulse
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_intensity;
	
	// Fresnel rim glow
	float fresnel = pow(1.0 - max(dot(VIEW, NORMAL), 0.0), 2.5);
	
	// Core blending: Edge Cyan -> Vibrant Plasma -> White-Hot Core Streams
	vec3 col = mix(edge_color.rgb, plasma_color.rgb, smoothstep(0.2, 0.7, plasma));
	col = mix(col, core_color.rgb, smoothstep(0.65, 0.95, plasma) * 0.85);
	col = mix(col, plasma_color.rgb * 1.3, fresnel * 0.6);
	
	// Optional electrical arc crackle: a sharp, fast-flickering high-frequency noise
	// layer, opt-in only (default 0.0 leaves every existing usage unchanged).
	float crackle = 0.0;
	if (crackle_intensity > 0.0) {
		float bolt = noise2d(uv * vec2(0.4, 6.0) + vec2(0.0, -TIME * 14.0));
		crackle = smoothstep(0.88, 1.0, bolt) * crackle_intensity;
	}

	ALBEDO = col * 0.3; // Base diffuse
	EMISSION = (col * emission_energy * pulse) + (core_color.rgb * crackle * 4.0); // HDR Glow emission
	ROUGHNESS = 0.2;
	SPECULAR = 0.8;
}
