shader_type canvas_item;
render_mode skip_vertex_transform, unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float alpha = 1.0;
uniform float inner_radius = 0.0;
uniform float outer_radius = 1.0;

global uniform float blood_vignete;
global uniform float rumble_vignete;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 mix_color = mix(screen_color, screen_color * vec4(1.0, 0.1, 0.1, 1.0), blood_vignete).rgb;

	float x = abs(UV.r-.5)*2.0;
	float y = abs(UV.g-.5)*2.0;
	float q = 1.0-(1.0-sqrt(x*x+y*y)/outer_radius)/(1.0-inner_radius);
	vec3 vignete = vec3(1.0 - q*alpha);

	vec3 bw = vec3((screen_color.r+screen_color.g+screen_color.b)/3.0);

	mix_color = mix_color * clamp(vignete, 0.0, 1.0);

	mix_color = mix(mix_color, bw, clamp(q, 0.0, 1.0));

	mix_color = mix(mix_color, bw, rumble_vignete);

	COLOR = vec4(mix_color, 1.0);

	//COLOR = vec4(clamp(vignete, 0.0, 1.0), 1.0);
}
