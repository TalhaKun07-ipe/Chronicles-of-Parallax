shader_type canvas_item;

// Animated golden filigree shimmer along a Control's border for UndertaleDialogueBox.
uniform vec4 glow_color : source_color = vec4(0.92, 0.75, 0.35, 1.0);
uniform float glow_speed : hint_range(0.0, 5.0) = 1.4;
uniform float border_width : hint_range(0.0, 0.2) = 0.045;

void fragment() {
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge = min(edge_x, edge_y);
	float border = 1.0 - smoothstep(0.0, border_width, edge);
	float shimmer = 0.5 + 0.5 * sin((UV.x + UV.y) * 8.0 - TIME * glow_speed * 3.0);
	vec3 glow = glow_color.rgb * (0.7 + shimmer * 0.3);
	
	// Preserve incoming panel COLOR from StyleBoxFlat and apply golden border shimmer
	COLOR = vec4(mix(COLOR.rgb, glow, border * 0.85), COLOR.a);
}
