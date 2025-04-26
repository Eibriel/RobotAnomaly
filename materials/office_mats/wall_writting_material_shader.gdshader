// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D texture_writting_1 : source_color, filter_linear_mipmap, repeat_enable;
uniform float writting_1_weight : hint_range(0.0, 1.0);
//uniform sampler2D texture_writting_2 : source_color, filter_linear_mipmap, repeat_enable;
//uniform float writting_2_weight : hint_range(0.0, 1.0);
//uniform sampler2D texture_writting_3 : source_color, filter_linear_mipmap, repeat_enable;
//uniform float writting_3_weight : hint_range(0.0, 1.0);

uniform vec4 fog_color : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01);
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01);
uniform float alpha_hash_scale : hint_range(0.0, 2.0, 0.01);
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

//uniform vec2 UV_2;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	UV2 = UV * uv2_scale.xy + uv2_offset.xy;
}

float lerp(float a, float b, float w) {
	return mix(a, b, w);
}

float inverse_lerp(float p_from, float p_to, float p_value) {
	return (p_value - p_from) / (p_to - p_from);
}

float remap(float p_value, float p_istart, float p_istop, float p_ostart, float p_ostop) {
	return lerp(p_ostart, p_ostop, inverse_lerp(p_istart, p_istop, p_value));
}

vec4 alpha_over(vec4 color_background, vec4 color_foreground) {
	return vec4(
		mix(color_background.rgb*color_background.a, color_foreground.rgb, color_foreground.a),
		clamp(color_background.a+color_foreground.a, 0.0, 1.0));
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, UV2);

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Fog
	float fog_alpha = clamp(smoothstep(distance_fade_min, distance_fade_max, length(VERTEX)), 0.0, 1.0);
	vec4 fog = vec4(fog_color.rgb, fog_alpha);

	// Animated Texture
	float val = texture(texture_writting_1, base_uv).g;
	float texture_alpha = clamp(remap(val, writting_1_weight, writting_1_weight*1.1, 1.0, 0.0), 0.0, 0.8);
	albedo_tex.a = texture_alpha;

	vec4 comp = alpha_over(albedo_tex, fog);

	ALPHA = comp.a;
	ALBEDO = comp.rgb;
}
