shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#endif
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z / 3.0;
	linear_depth -= 0.0;

	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	// Visualize linear depth
	float fog = 1.0 - fract(linear_depth);
	//ALBEDO.rgb = texture(screen_texture, SCREEN_UV).rgb * vec3(fog+2.0);
	//ALBEDO.rgb = vec3(fog+10.0);
	ALBEDO.rgb = texture(screen_texture, SCREEN_UV).rgb * 5.0;

	// Visualize world coordinates
	//ALBEDO.rgb = fract(world_position).xyz;
}