shader_type canvas_item;
render_mode skip_vertex_transform, unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

global uniform float blood_vignete;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = mix(screen_color, screen_color * vec4(1.0, 0.1, 0.1, 1.0), blood_vignete);
	//COLOR = vec4(1, 0, 0, 1);
}

